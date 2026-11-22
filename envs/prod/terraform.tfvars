# Ambiente PROD: rede separada (10.20.0.0/16) para nunca colidir com o DEV
# e um tipo de máquina um pouco maior. No lab também roda no LocalStack.
environment    = "prod"
vpc_cidr       = "10.20.0.0/16"
instance_type  = "t3.small"
use_localstack = true
ami_id         = "ami-785db401"
