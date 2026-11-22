# State remoto no S3 com "configuração parcial": o bloco fica vazio aqui e os valores
# vêm de envs/<env>/backend.hcl no init (backend não aceita variáveis):
#
#   terraform init -backend-config=envs/dev/backend.hcl
#
# Por que remoto? O state é a "memória" do Terraform. Local, ele some se o disco morrer
# e duas pessoas não conseguem trabalhar juntas. No S3: versionado, criptografado,
# compartilhado e com LOCK (use_lockfile), para dois applies não rodarem ao mesmo tempo.
terraform {
  backend "s3" {}
}
