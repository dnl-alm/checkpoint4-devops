#!/bin/bash
set -e

# ALTERE PARA SEU RM E SUA REGIÃO (Política)
rm=rm563045
location="canadacentral"
resourceGroup="rg-rm563045-mercadoexpress"
acrName="rm563045acrme"
# Nome do ACI com o RM como prefixo, conforme exigido no enunciado
aciName="${rm}-oracle-mercadoexpress"
imageName="${rm}-oracle-mercadoexpress"
tag="v1"
storageAccountName="volume$rm"
file_share_name="${rm}-oracle-mercadoexpress-volume"
storage_key=$(az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv)
keyVaultName="keyvault-$rm"

# Registra o Serviço de ACI na Assinatura
az provider register --namespace Microsoft.ContainerInstance

# Deploy do Container Oracle
az container create \
  --resource-group $resourceGroup \
  --name $aciName \
  --location $location \
  --image $acrName.azurecr.io/$imageName:$tag \
  --cpu 1 \
  --memory 3.5 \
  --os-type Linux \
  --dns-name-label oracle-mercadoexpress-$rm \
  --ports 1521 \
  --registry-login-server $acrName.azurecr.io \
  --registry-username $(az keyvault secret show --vault-name $keyVaultName --name acr-username --query value -o tsv) \
  --registry-password $(az keyvault secret show --vault-name $keyVaultName --name acr-password --query value -o tsv) \
  --azure-file-volume-account-name $storageAccountName \
  --azure-file-volume-account-key $storage_key \
  --azure-file-volume-share-name $file_share_name \
  --azure-file-volume-mount-path /opt/oracle/oradata \
  --environment-variables \
    ORACLE_PASSWORD=$(az keyvault secret show --vault-name $keyVaultName --name oracle-password --query value -o tsv) \
    ORACLE_DATABASE=$(az keyvault secret show --vault-name $keyVaultName --name oracle-database --query value -o tsv) \
    APP_USER=$(az keyvault secret show --vault-name $keyVaultName --name app-user --query value -o tsv) \
    APP_USER_PASSWORD=$(az keyvault secret show --vault-name $keyVaultName --name app-user-password --query value -o tsv) \
  --restart-policy Always
