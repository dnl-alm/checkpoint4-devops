#!/bin/bash
set -e

# ALTERE PARA SEU RM E SUA REGIÃO (Política)
rm=rm563045
location="canadacentral"
resourceGroup="rg-rm563045-mercadoexpress"
acrName="rm563045acrme"
# Nome do ACI com o RM como prefixo, conforme exigido no enunciado
aciName="${rm}-api-mercadoexpress"
aciNameOracle="${rm}-oracle-mercadoexpress"
imageName="${rm}-api-mercadoexpress"
tag="v1"
keyVaultName="keyvault-$rm"

oracleFQDN=$(az container show --resource-group $resourceGroup --name $aciNameOracle --query ipAddress.fqdn --output tsv)

# Registra o Serviço de ACI na Assinatura
az provider register --namespace Microsoft.ContainerInstance

# Deploy do Container da API
az container create \
  --resource-group $resourceGroup \
  --name $aciName \
  --location $location \
  --image $acrName.azurecr.io/$imageName:$tag \
  --cpu 1 \
  --memory 1 \
  --os-type Linux \
  --dns-name-label api-mercadoexpress-$rm \
  --ports 8080 \
  --registry-login-server $acrName.azurecr.io \
  --registry-username $(az keyvault secret show --vault-name $keyVaultName --name acr-username --query value -o tsv) \
  --registry-password $(az keyvault secret show --vault-name $keyVaultName --name acr-password --query value -o tsv) \
  --environment-variables \
    ORACLE_HOST=$oracleFQDN \
    SPRING_DATASOURCE_URL=$(az keyvault secret show --name spring-datasource-url --vault-name $keyVaultName --query value -o tsv | sed "s/ORACLE_HOST_PLACEHOLDER/$oracleFQDN/") \
    SPRING_DATASOURCE_USERNAME=$(az keyvault secret show --name spring-datasource-username --vault-name $keyVaultName --query value -o tsv) \
    SPRING_DATASOURCE_PASSWORD=$(az keyvault secret show --name spring-datasource-password --vault-name $keyVaultName --query value -o tsv) \
  --restart-policy Always

# O comando sed troca o placeholder pelo FQDN público do ACI do Oracle em runtime.
# ORACLE_HOST também vai como variável separada — é o que o wait-for-oracle.sh
# do Dockerfile.api usa para saber em qual host testar a porta 1521
# (não é mais "localhost", já que agora são dois ACIs distintos).

# Testes após a criação
#
# fqdnApi=$(az container show --resource-group rg-rm563045-mercadoexpress --name rm563045-api-mercadoexpress --query ipAddress.fqdn --output tsv)
#
# Ajuste o path abaixo para o mapeamento real do seu MercadoController
# (ex: /mercado, /api/mercado — confirme no @RequestMapping da classe)
#
# curl -X GET http://$fqdnApi:8080/mercado
#
# curl -X POST http://$fqdnApi:8080/mercado \
#   -H "Content-Type: application/json" \
#   -d '{
#     "nome": "Sabonete",
#     "tipo": "Higiene",
#     "setor": "A1",
#     "tamanho": "M",
#     "preco": 5.90
#   }'
