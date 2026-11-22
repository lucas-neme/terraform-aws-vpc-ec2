#!/usr/bin/env bash
# Teste de fumaça depois do "make apply" no LocalStack: confere, pela API (aws cli),
# que o que o Terraform diz ter criado existe mesmo.
set -euo pipefail

ENV="${ENV:-dev}"
ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

awsl() { aws --endpoint-url "$ENDPOINT" --output text "$@"; }

falhas=0
check() { # check "descrição" "esperado" "obtido"
  if [ "$2" = "$3" ]; then
    echo "  OK    $1"
  else
    echo "  FALHA $1 (esperado: $2, obtido: $3)"
    falhas=$((falhas + 1))
  fi
}

VPC_ID=$(terraform output -raw vpc_id)
INSTANCE_ID=$(terraform output -raw instance_id)
echo "Ambiente $ENV | VPC $VPC_ID | EC2 $INSTANCE_ID"

check "VPC existe" "$VPC_ID" "$(awsl ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].VpcId')"
check "4 sub-redes na VPC" "4" "$(awsl ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'length(Subnets)')"
check "2 sub-redes públicas" "2" "$(awsl ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=tag:Tier,Values=public --query 'length(Subnets)')"
check "IGW anexado à VPC" "1" "$(awsl ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" --query 'length(InternetGateways)')"
check "EC2 rodando" "running" "$(awsl ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name')"
check "EC2 com IMDSv2 obrigatório" "required" "$(awsl ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].MetadataOptions.HttpTokens')"
check "Tag Environment=$ENV" "$ENV" "$(awsl ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[0].Tags[?Key=='Environment'].Value | [0]")"
check "State remoto gravado no S3" "1" "$(awsl s3api list-objects-v2 --bucket tfstate-getrak-lab --prefix "vpc-ec2/$ENV/terraform.tfstate" --query 'length(Contents)')"

if [ "$falhas" -gt 0 ]; then
  echo "Fumaça: $falhas falha(s)"
  exit 1
fi
echo "Fumaça: tudo certo"
