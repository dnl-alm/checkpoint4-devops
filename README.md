# MercadoExpress — Containers em Nuvem (Checkpoint)

API Spring Boot (CRUD + HATEOAS nível 3) com banco MySQL, containerizada, publicada no Azure Container Registry (ACR) e executada em dois Azure Container Instances (ACI) separados, com segredos no Azure Key Vault e persistência de dados em Azure Storage (File Share).

RM do representante do grupo: **563045** (usado como prefixo em todos os recursos).

# Desenvolvido por

- Guilherme Cintra RM562850
- Erick de Faria Gama RM561951
- Matheus Nascimento Corregio RM563765
- Pedro Fonseca de Almeida RM563466
- Daniel Fonseca de Almeida RM563045

## Arquitetura

- **Dois ACIs separados**: `rm563045-mysql-mercadoexpress` e `rm563045-api-mercadoexpress`, cada um com seu próprio FQDN público (`--dns-name-label`).
- **Azure Key Vault** guarda todas as credenciais (banco e ACR) — nada de senha em texto puro nos scripts de deploy.
- **Azure File Share** monta `/var/lib/mysql`, garantindo que os dados sobrevivem a restart/redeploy do container do banco.
- O container da API **não roda como root** (usuário `appuser` dedicado no Dockerfile).

## Pré-requisitos

- Docker instalado e rodando
- Azure CLI (`az`) autenticado (`az login`) na assinatura correta
- Cliente `mysql` instalado localmente (opcional — dá pra rodar os `SELECT` de dentro do próprio container via `az container exec`, veja o Passo 6)
- `jq` (opcional, só pra formatar JSON do `curl` nos testes)

## Estrutura de arquivos no repositório

```
.
├── README.md
├── docker-compose.yml
├── Dockerfile.mysql
├── Dockerfile.api
├── wait-for-db.sh
├── docker-entrypoint-initdb.d/
│   └── init.sql
├── src/                          # código-fonte da API
├── pom.xml
└── azure/
    ├── 00-setup-acr.sh
    ├── 01-storage-account.sh
    ├── 02-keyvault.sh
    ├── 03-deploy-mysql-aci.sh
    ├── 04-deploy-api-aci.sh
    └── test-crud.sh
```

## Passo 1 — Configuração do lado do Spring Boot

No `pom.xml`, dependência do driver MySQL:

```xml
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <scope>runtime</scope>
</dependency>
```

No `application.properties`:

```properties
spring.application.name=mercadoexpress
server.port=8080

spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=2
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=60000
spring.datasource.hikari.max-lifetime=300000
spring.datasource.hikari.validation-timeout=5000

spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

O schema é gerenciado pelo `init.sql` (não pelo Hibernate), por isso `ddl-auto=none`. **Não defina `hibernate.dialect` manualmente** — o Spring Boot detecta o dialeto MySQL sozinho a partir do driver.

## Passo 2 — Build e teste local

```bash
docker compose up --build
```

Aguarde o healthcheck do MySQL ficar `healthy` (a API só sobe depois disso, via `depends_on`). Teste local:

```bash
curl http://localhost:8080/mercado
```

Se responder com a lista HATEOAS vazia, está tudo certo. Derrube o ambiente local antes de seguir:

```bash
docker compose down
```

## Passo 3 — Criar o Resource Group e o ACR

```bash
cd azure
bash 00-setup-acr.sh
```

Cria o Resource Group (`rg-rm563045-mercadoexpress`) e o Azure Container Registry (`rm563045acrme`) com usuário admin habilitado — pré-requisito pros passos seguintes (push de imagem e leitura de credenciais no `02-keyvault.sh`).

## Passo 4 — Build das imagens e push pro ACR

```bash
az acr login --name rm563045acrme

docker build -f Dockerfile.mysql -t rm563045acrme.azurecr.io/rm563045-mysql-mercadoexpress:v1 .
docker push rm563045acrme.azurecr.io/rm563045-mysql-mercadoexpress:v1

docker build -f Dockerfile.api -t rm563045acrme.azurecr.io/rm563045-api-mercadoexpress:v1 .
docker push rm563045acrme.azurecr.io/rm563045-api-mercadoexpress:v1
```

## Passo 5 — Provisionar o restante da infraestrutura em nuvem

Continue executando os scripts em `azure/`, **nesta ordem** (cada um depende do anterior):

```bash
bash 01-storage-account.sh   # Resource Group + Storage Account + File Share
bash 02-keyvault.sh          # Key Vault + segredos (MySQL e ACR)
bash 03-deploy-mysql-aci.sh  # ACI do banco (lê segredos do Key Vault)
bash 04-deploy-api-aci.sh    # ACI da API (busca o FQDN do banco e injeta no datasource)
```

O `04-deploy-api-aci.sh` só funciona depois que o `03` já criou o ACI do banco — ele lê o FQDN dele em tempo de execução (`az container show ... --query ipAddress.fqdn`) pra montar a `SPRING_DATASOURCE_URL` corretamente, já que são dois ACIs separados (não existe `localhost` compartilhado entre eles).

Acompanhe os logs até aparecer `ready for connections` (MySQL) e `Started MercadoexpressApplication` (API):

```bash
resourceGroup="rg-rm563045-mercadoexpress"

az container logs --resource-group $resourceGroup --name rm563045-mysql-mercadoexpress
az container logs --resource-group $resourceGroup --name rm563045-api-mercadoexpress
```

## Passo 6 — Testes em nuvem (evidência de CRUD)

```bash
resourceGroup="rg-rm563045-mercadoexpress"
fqdnApi=$(az container show --resource-group $resourceGroup --name rm563045-api-mercadoexpress --query ipAddress.fqdn -o tsv)
dbFQDN=$(az container show --resource-group $resourceGroup --name rm563045-mysql-mercadoexpress --query ipAddress.fqdn -o tsv)
```

**1. GET — estado inicial (deve vir vazio):**
```bash
curl -X GET "http://$fqdnApi:8080/mercado"
```

**2. SELECT — confirma o estado inicial no banco:**
```bash
mysql -h $dbFQDN -P 3306 -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```

**3. POST — criar um registro:**
```bash
curl -X POST "http://$fqdnApi:8080/mercado" \
  -H "Content-Type: application/json" \
  -d '{"nome": "Sabonete", "tipo": "Higiene", "setor": "A1", "tamanho": "0.01", "preco": 5.90}'
```

**4. SELECT — confirma o INSERT:**
```bash
mysql -h $dbFQDN -P 3306 -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```

**5. GET por id:**
```bash
curl -X GET "http://$fqdnApi:8080/mercado/1"
```

**6. PUT — atualizar:**
```bash
curl -X PUT "http://$fqdnApi:8080/mercado/1" \
  -H "Content-Type: application/json" \
  -d '{"nome": "Sabonete - ALTERADO", "tipo": "Higiene", "setor": "A1", "tamanho": "0.01", "preco": 6.50}'
```

**7. SELECT — confirma o UPDATE:**
```bash
mysql -h $dbFQDN -P 3306 -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```

**8. DELETE:**
```bash
curl -X DELETE "http://$fqdnApi:8080/mercado/1"
```

**9. SELECT — confirma o DELETE (tabela vazia de novo):**
```bash
mysql -h $dbFQDN -P 3306 -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```

Print de cada resposta do `curl` junto com o `SELECT` correspondente é a evidência exigida no item 4 do checkpoint.

### Alternativa: rodar o SELECT sem cliente mysql local

Se você não tem o cliente `mysql` instalado na sua máquina, dá pra rodar os `SELECT` de duas formas sem instalar nada:

**Opção A — usando o Docker que você já tem:**
```bash
docker run -it --rm mysql:8.0 mysql -h $dbFQDN -P 3306 -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```

**Opção B — entrando direto no container do banco no ACI:**
```bash
az container exec \
  --resource-group $resourceGroup \
  --name rm563045-mysql-mercadoexpress \
  --container-name rm563045-mysql-mercadoexpress \
  --exec-command "/bin/bash"
```
Isso abre um shell dentro do próprio container. De lá dentro, conecta em `localhost` (o cliente `mysql` já vem na imagem oficial):
```bash
mysql -u mercadoexpress_app -p mercadoexpress -e "SELECT * FROM tds_tb_mercado;"
```
`exit` pra sair do shell depois.

## Onde ver as senhas/segredos

Tudo fica no Key Vault, nunca em texto puro nos scripts de deploy:

```bash
az keyvault secret show --vault-name keyvault-rm563045 --name mysql-password --query value -o tsv
```

## Limpeza dos recursos (opcional, ao final)

```bash
az group delete --name rg-rm563045-mercadoexpress --yes --no-wait
```