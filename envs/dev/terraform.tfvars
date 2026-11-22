# Ambiente DEV: rede 10.10.0.0/16, máquina mínima, roda no LocalStack.
environment    = "dev"
vpc_cidr       = "10.10.0.0/16"
instance_type  = "t3.micro"
use_localstack = true
ami_id         = "ami-785db401" # Ubuntu simulada pelo LocalStack (na AWS real, apague esta linha)
