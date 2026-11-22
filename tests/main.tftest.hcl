# Testes nativos do Terraform ("terraform test", 1.6+).
# mock_provider (1.7+) finge ser a AWS: nada é criado, o teste roda offline em segundos,
# sem LocalStack e sem conta. Serve para garantir a LÓGICA (CIDRs, validações, segurança).
mock_provider "aws" {}

run "cria_2_subredes_publicas_e_2_privadas_com_cidrs_esperados" {
  command = apply

  variables {
    environment = "dev"
    vpc_cidr    = "10.10.0.0/16"
    ami_id      = "ami-teste"
  }

  assert {
    condition     = module.network.public_subnet_cidrs == ["10.10.0.0/24", "10.10.1.0/24"]
    error_message = "Sub-redes públicas deveriam ser 10.10.0.0/24 e 10.10.1.0/24."
  }

  assert {
    condition     = module.network.private_subnet_cidrs == ["10.10.10.0/24", "10.10.11.0/24"]
    error_message = "Sub-redes privadas deveriam ser 10.10.10.0/24 e 10.10.11.0/24."
  }
}

run "prod_usa_rede_propria" {
  command = apply

  variables {
    environment   = "prod"
    vpc_cidr      = "10.20.0.0/16"
    instance_type = "t3.small"
    ami_id        = "ami-teste"
  }

  assert {
    condition     = module.network.public_subnet_cidrs[0] == "10.20.0.0/24"
    error_message = "Prod deveria usar a faixa 10.20.0.0/16."
  }
}

run "rejeita_ambiente_desconhecido" {
  command = plan

  variables {
    environment = "qa"
    vpc_cidr    = "10.10.0.0/16"
    ami_id      = "ami-teste"
  }

  expect_failures = [var.environment]
}

run "rejeita_instancia_cara" {
  command = plan

  variables {
    environment   = "dev"
    vpc_cidr      = "10.10.0.0/16"
    instance_type = "m5.24xlarge"
    ami_id        = "ami-teste"
  }

  expect_failures = [var.instance_type]
}

run "rejeita_vpc_que_nao_e_barra_16" {
  command = plan

  variables {
    environment = "dev"
    vpc_cidr    = "10.10.0.0/24"
    ami_id      = "ami-teste"
  }

  expect_failures = [var.vpc_cidr]
}

# Testa o módulo compute sozinho: aqui os recursos dele ficam visíveis para o assert.
run "compute_exige_imdsv2_disco_criptografado_e_ssh_fechado" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    name_prefix        = "teste"
    project            = "getrak-lab"
    environment        = "dev"
    vpc_id             = "vpc-teste"
    subnet_id          = "subnet-teste"
    ami_id             = "ami-teste"
    instance_type      = "t3.micro"
    allowed_http_cidrs = ["0.0.0.0/0"]
  }

  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 precisa ser obrigatório."
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted == true
    error_message = "O disco raiz precisa ser criptografado."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 0
    error_message = "SSH deveria estar fechado quando ssh_cidr = null."
  }
}
