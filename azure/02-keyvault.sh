#!/bin/bash
set -e

# ALTERE PARA SEU RM
rm=rm563045
resourceGroup="rg-rm563045-mercadoexpress"
location="canadacentral"

# --- MySQL ---
MYSQL_ROOT_PASSWORD=senha-root-mercadoexpress
MYSQL_DATABASE=mercadoexpress
MYSQL_USER=mercadoexpress_app
MYSQL_PASSWORD=senha-app-mercadoexpress

# --- Datasource da API ---
# "DB_HOST_PLACEHOLDER" é substituído pelo FQDN real do ACI do MySQL
# no momento do deploy da API (veja 04-deploy-api-aci.sh).
SPRING_DATASOURCE_URL="jdbc:mysql://DB_HOST_PLACEHOLDER:3306/mercadoexpress?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
SPRING_DATASOURCE_USERNAME=$MYSQL_USER
SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD

acrName="rm563045acrme"
ACRUSERNAME=$(az acr credential show --name $acrName --resource-group $resourceGroup --query username --output tsv)
ACRPASSWORD=$(az acr credential show --name $acrName --resource-group $resourceGroup --query passwords[0].value --output tsv)
keyVaultName="keyvault-$rm"

az provider register --namespace Microsoft.KeyVault

if ! az keyvault show --name "$keyVaultName" --resource-group "$resourceGroup" &> /dev/null; then
  az keyvault create --name "$keyVaultName" --resource-group "$resourceGroup" --location "$location"
else
  echo "Key Vault '$keyVaultName' já existe no Grupo de Recurso '$resourceGroup'."
fi

az role assignment create \
  --assignee $(az account show --query user.name -o tsv) \
  --role "Key Vault Administrator" \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName

sleep 15

az keyvault secret set --vault-name $keyVaultName --name mysql-root-password --value "$MYSQL_ROOT_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name mysql-database --value "$MYSQL_DATABASE"
az keyvault secret set --vault-name $keyVaultName --name mysql-user --value "$MYSQL_USER"
az keyvault secret set --vault-name $keyVaultName --name mysql-password --value "$MYSQL_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-url --value "$SPRING_DATASOURCE_URL"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-username --value "$SPRING_DATASOURCE_USERNAME"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-password --value "$SPRING_DATASOURCE_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name acr-username --value "$ACRUSERNAME"
az keyvault secret set --vault-name $keyVaultName --name acr-password --value "$ACRPASSWORD"