# Roteiro de estudo — terraform-aws-vpc-ec2

Leitura de ~10 minutos. Cada arquivo e cada decisão explicados como eu falaria numa entrevista.

## 1. O projeto em 30 segundos

"Montei com Terraform uma rede AWS do jeito que se faz em produção, só que pequena: uma VPC com sub-redes
públicas e privadas em duas zonas de disponibilidade, internet gateway, tabelas de rota, um security group
mínimo e uma EC2 que instala o Nginx pelo user data. O código está em dois módulos, network e compute, com
variáveis validadas e dois ambientes, dev e prod. O state fica num bucket S3 com lock. Tudo roda de graça no
LocalStack, e o CI roda fmt, validate, testes nativos do Terraform, tflint e checkov."

## 2. Arquivo por arquivo

| Arquivo | O que faz | Como explicar |
|---|---|---|
| `versions.tf` | fixa Terraform ≥ 1.10 e provider AWS `~> 6.0` | "Travo versões para o mesmo código dar o mesmo resultado hoje e daqui a seis meses. O `~>` aceita correções da 6.x, mas não a 7, que pode quebrar." |
| `.terraform.lock.hcl` | registra a versão exata e o hash do provider | "É como o package-lock do Node: todo mundo usa exatamente o mesmo binário." |
| `providers.tf` | configura o provider AWS; com `use_localstack` aponta os endpoints para o LocalStack | "Um bloco `dynamic` liga os endpoints locais só no lab. Na AWS real, basta `use_localstack=false`." |
| `backend.tf` | `backend "s3" {}` vazio | "Backend não aceita variável, então uso configuração parcial: os valores vêm do `backend.hcl` de cada ambiente no `init`." |
| `bootstrap/` | cria o bucket do state (versionado, criptografado, sem acesso público, com expiração de versões antigas) | "É o ovo e a galinha: o backend precisa do bucket antes do `init`. O bootstrap roda uma vez, com state local." |
| `variables.tf` | entradas com tipo, descrição e `validation` | "Validação falha no `plan`, antes de criar qualquer coisa: só aceito dev/prod, VPC /16, e tipos de máquina baratos." |
| `locals.tf` | `name_prefix`, tags comuns, escolha da AMI | "Locals evitam repetir regra. Nome e tags num lugar só." |
| `main.tf` | data source da AMI Ubuntu + chamada dos módulos | "A raiz só compõe: liga a saída da rede (IDs) à entrada do compute." |
| `modules/network` | VPC, 2 públicas + 2 privadas, IGW, 2 route tables, SG default fechado | "Pública tem rota 0.0.0.0/0 para o IGW; privada não tem saída. Para sair precisaria de NAT, que custa ~US$ 32/mês." |
| `modules/compute` | SG + regras, EC2 com user data, IMDSv2 e disco criptografado | "Entrada só na 80; saída só 80/443/53; SSH fechado por padrão." |
| `user_data.sh.tftpl` | script do primeiro boot que instala o Nginx | "`templatefile` injeta projeto e ambiente. Como o user data só roda no primeiro boot, `user_data_replace_on_change` recria a instância se o script mudar." |
| `outputs.tf` | IDs e URL | "Outputs são a interface do módulo: outro código ou um script consome isso." |
| `envs/dev` e `envs/prod` | `.tfvars` + `backend.hcl` por ambiente | "Mesmo código, configuração diferente. Chave de state diferente: um `destroy` no dev nunca toca o prod." |
| `tests/main.tftest.hcl` | 6 testes com `mock_provider` | "Testo a lógica sem nuvem: CIDRs certos, validações que têm de falhar, IMDSv2 obrigatório." |
| `scripts/smoke.sh` | confere pela API do LocalStack o que foi criado | "Teste de fumaça: o Terraform disse que criou; o script pergunta à 'AWS' se existe mesmo." |
| `.tflint.hcl` / `.checkov.yaml` | lint e segurança | "tflint pega erro de boa prática e de AWS; checkov pega má configuração de segurança. Cada exceção está comentada com o motivo." |
| `Makefile` | atalhos (`make up/apply/smoke/destroy/test`) | "Qualquer pessoa roda o projeto sem decorar comandos." |
| `.github/workflows/ci.yml` | CI em todo push e PR | "Dois jobs em paralelo: Terraform (fmt, validate, test, tflint) e checkov." |

## 3. As decisões, em linguagem de entrevista

**Por que state remoto?** O state é a memória do Terraform: o mapa entre o código e o que existe na nuvem.
Local, ele some se o disco morrer, não dá para trabalhar em equipe e pode vazar dados. No S3 ele fica
versionado (dá para voltar), criptografado, sem acesso público e acessível ao time e ao CI.

**Por que lock?** Para dois `apply` não rodarem ao mesmo tempo sobre o mesmo state e corromperem tudo.
Desde o Terraform 1.10 o S3 faz o lock sozinho (`use_lockfile = true`, um arquivo `.tflock` ao lado do state).
Antes era preciso uma tabela DynamoDB.

**Por que módulos?** Separação de responsabilidades e reuso. A mesma rede pode servir outra aplicação, e cada
módulo tem entradas (variables) e saídas (outputs) claras, como uma função.

**Por que `for_each` e não `count` nas sub-redes?** `count` identifica pelo índice; se a lista de AZs mudar
de ordem, o Terraform destrói e recria sub-redes. `for_each` identifica pela chave (o nome da AZ), que é estável.
Uso `count` só para "liga/desliga", como a regra de SSH.

**Por que duas AZs?** Alta disponibilidade mínima: se uma zona cair, a outra continua. É também o que um
Load Balancer exige.

**Pública × privada?** É a rota que define: a pública tem rota padrão para o Internet Gateway. Banco de dados e
aplicação interna ficam na privada, sem entrada da internet.

**Por que validar variáveis?** Erro cedo e barato. Melhor o `plan` recusar `m5.24xlarge` do que a fatura chegar.

**Por que IMDSv2?** O endpoint de metadados entrega credenciais da instância. O v2 exige um token de sessão,
o que bloqueia o ataque clássico de SSRF que leu esse endpoint em vazamentos famosos.

**Por que LocalStack?** Custo zero e ciclo rápido para aprender e testar. Limitação: a EC2 é simulada, então
o Nginx só responde na AWS real. A versão está fixada em 4.14 porque a `latest` passou a exigir licença.

**Por que `plan -out` e depois `apply` do arquivo?** Garante que o que foi aplicado é exatamente o que foi revisado.

## 4. Comandos que vale saber de cor

```bash
terraform init -backend-config=envs/dev/backend.hcl   # baixa provider e liga o backend
terraform fmt -recursive                              # formata
terraform validate                                    # sintaxe e tipos
terraform plan -var-file=envs/dev/terraform.tfvars -out=dev.tfplan
terraform apply dev.tfplan
terraform state list                                  # o que o Terraform gerencia
terraform output -raw vpc_id
terraform destroy -var-file=envs/dev/terraform.tfvars
terraform test                                        # testes nativos
```

## 5. Dez perguntas prováveis (com resposta curta)

1. **O que é o state e por que não versionar no git?**
   É o mapa código → recursos reais. No git ele vaza dados sensíveis e gera conflito; vai num backend remoto com lock.
2. **O que acontece se dois colegas derem `apply` juntos?**
   Com lock, o segundo espera ou falha com "state locked". Sem lock, o state pode corromper.
3. **Diferença entre `terraform plan` e `apply`?**
   `plan` mostra o que vai mudar sem mexer em nada; `apply` executa. Em equipe, revisa-se o plan antes.
4. **Como você separa dev e prod?**
   Mesmo código, um `.tfvars` e uma chave de state por ambiente. Em empresa maior: contas AWS separadas.
5. **Sub-rede pública × privada?**
   A pública tem rota 0.0.0.0/0 para o Internet Gateway; a privada não. Para a privada sair, NAT Gateway.
6. **Security group × NACL?**
   SG é stateful e fica na instância (resposta volta sozinha); NACL é stateless e fica na sub-rede (regras de ida e volta).
7. **Para que serve o `.terraform.lock.hcl`?**
   Fixa versão e hash dos providers; todos (e o CI) usam o mesmo binário. Ele vai para o git.
8. **Como você testa código Terraform?**
   fmt/validate, tflint, checkov, `terraform test` com mock e um teste de fumaça depois do apply (aqui no LocalStack).
9. **Alguém mudou algo no console. E agora?**
   É drift. O `plan` mostra a diferença; ou se traz para o código, ou o `apply` desfaz. Regra: mudança só pelo código.
10. **`count` ou `for_each`?**
    `for_each` quando os itens têm identidade (AZs, nomes); `count` para quantidade simples ou liga/desliga.
