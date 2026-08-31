#!/bin/bash
set -e

# ALTERE PARA SEU RM
rm=rm563045
resourceGroup="rg-rm563045-mercadoexpress"
location="canadacentral"

# --- Oracle ---
ORACLE_PASSWORD=senha-sys-mercadoexpress
ORACLE_DATABASE=mercadoexpress
APP_USER=mercadoexpress_app
APP_USER_PASSWORD=senha-app-mercadoexpress

# --- Datasource da API ---
# "ORACLE_HOST_PLACEHOLDER" é substituído pelo FQDN real do ACI do Oracle
# no momento do deploy da API (veja 04-deploy-api-aci.sh) — como são dois
# ACIs separados agora (não um container group), não existe "localhost"
# em comum entre eles.
SPRING_DATASOURCE_URL="jdbc:oracle:thin:@//ORACLE_HOST_PLACEHOLDER:1521/mercadoexpress"
SPRING_DATASOURCE_USERNAME=$APP_USER
SPRING_DATASOURCE_PASSWORD=$APP_USER_PASSWORD

acrName="rm563045acrme"
ACRUSERNAME=$(az acr credential show --name $acrName --resource-group $resourceGroup --query username --output tsv)
ACRPASSWORD=$(az acr credential show --name $acrName --resource-group $resourceGroup --query passwords[0].value --output tsv)
keyVaultName="keyvault-$rm"

# Registra o Serviço do Key Vault na Assinatura
az provider register --namespace Microsoft.KeyVault

# Cria o Key Vault
if ! az keyvault show --name "$keyVaultName" --resource-group "$resourceGroup" &> /dev/null; then
  az keyvault create --name "$keyVaultName" --resource-group "$resourceGroup" --location "$location"
else
  echo "Key Vault '$keyVaultName' já existe no Grupo de Recurso '$resourceGroup'."
fi

# Concede acesso de ADM no Key Vault para nossa Assinatura
az role assignment create \
  --assignee $(az account show --query user.name -o tsv) \
  --role "Key Vault Administrator" \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName

sleep 15

# Armazena os dados sensíveis
az keyvault secret set --vault-name $keyVaultName --name oracle-password --value "$ORACLE_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name oracle-database --value "$ORACLE_DATABASE"
az keyvault secret set --vault-name $keyVaultName --name app-user --value "$APP_USER"
az keyvault secret set --vault-name $keyVaultName --name app-user-password --value "$APP_USER_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-url --value "$SPRING_DATASOURCE_URL"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-username --value "$SPRING_DATASOURCE_USERNAME"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-password --value "$SPRING_DATASOURCE_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name acr-username --value "$ACRUSERNAME"
az keyvault secret set --vault-name $keyVaultName --name acr-password --value "$ACRPASSWORD"
