#!/bin/bash
set -e

# Pré-requisito: ter feito `set -a; source .envaci; set +a` antes de rodar este script

# Registra o provider de Storage na assinatura (idempotente, pode rodar sempre)
az provider register --namespace Microsoft.Storage

# Cria a conta de armazenamento
az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS

# Cria o file share (volume persistente para /opt/oracle/oradata)
az storage share create \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$STORAGE_KEY" \
  --name "$FILE_SHARE"

echo "Storage Account: $STORAGE_ACCOUNT"
echo "File Share: $FILE_SHARE"
