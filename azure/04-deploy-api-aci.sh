#!/bin/bash
set -e

# ALTERE PARA SEU RM E SUA REGIÃO (Política)
rm=rm563045
location="canadacentral"
resourceGroup="rg-rm563045-mercadoexpress"
acrName="rm563045acrme"
aciName="${rm}-api-mercadoexpress"
aciNameMysql="${rm}-mysql-mercadoexpress"
imageName="${rm}-api-mercadoexpress"
tag="v1"
keyVaultName="keyvault-$rm"

dbFQDN=$(az container show --resource-group $resourceGroup --name $aciNameMysql --query ipAddress.fqdn --output tsv)

az provider register --namespace Microsoft.ContainerInstance

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
    DB_HOST=$dbFQDN \
    SPRING_DATASOURCE_URL=$(az keyvault secret show --name spring-datasource-url --vault-name $keyVaultName --query value -o tsv | sed "s/DB_HOST_PLACEHOLDER/$dbFQDN/") \
    SPRING_DATASOURCE_USERNAME=$(az keyvault secret show --name spring-datasource-username --vault-name $keyVaultName --query value -o tsv) \
    SPRING_DATASOURCE_PASSWORD=$(az keyvault secret show --name spring-datasource-password --vault-name $keyVaultName --query value -o tsv) \
  --restart-policy Always

# Testes após a criação
#
# fqdnApi=$(az container show --resource-group rg-rm563045-mercadoexpress --name rm563045-api-mercadoexpress --query ipAddress.fqdn --output tsv)
#
# curl -X GET http://$fqdnApi:8080/mercado