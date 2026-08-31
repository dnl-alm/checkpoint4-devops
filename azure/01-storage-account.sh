#!/bin/bash
set -e

# ALTERE PARA SEU RM
rm=rm563045
resourceGroup="rg-rm563045-mercadoexpress"
location="canadacentral"
storageAccountName="volume$rm"
file_share_name="${rm}-oracle-mercadoexpress-volume"

# Valida se o Grupo de Recursos existe e cria caso não exista
if ! az group show --name "$resourceGroup" &>/dev/null; then
  echo "Resource group '$resourceGroup' não existe. Criando..."
  az group create --name "$resourceGroup" --location "$location"
fi

# Registra o Serviço de Storage na Assinatura
az provider register --namespace Microsoft.Storage

# Cria a conta de armazenamento
if ! az storage account show --name "$storageAccountName" --resource-group "$resourceGroup" &>/dev/null; then
  az storage account create --resource-group "$resourceGroup" \
    --name "$storageAccountName" \
    --location "$location" \
    --sku Standard_LRS
else
  echo "A conta de armazenamento '$storageAccountName' já existe"
fi

# Recupera a connection string da Conta de Armazenamento
connection_string=$(az storage account show-connection-string --name "$storageAccountName" --resource-group "$resourceGroup" --query connectionString --output tsv)

# Cria o compartilhamento de arquivos (volume persistente do Oracle)
if ! az storage share exists --name "$file_share_name" --account-name "$storageAccountName" --connection-string "$connection_string" | grep true; then
  az storage share create --name "$file_share_name" --account-name "$storageAccountName" --connection-string "$connection_string"
else
  echo "O compartilhamento de arquivos '$file_share_name' já existe"
fi
