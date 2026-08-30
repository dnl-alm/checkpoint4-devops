#!/bin/bash
set -e

# Pré-requisito: ter feito `set -a; source .envaci; set +a` antes de rodar este script
# e ter rodado 07-storage-account.sh antes (para existir STORAGE_ACCOUNT/FILE_SHARE/STORAGE_KEY)

# IMPORTANTE: `az container create --file` NÃO expande ${VAR} sozinho.
# Por isso geramos o yaml final com envsubst antes de enviar pro Azure.
envsubst < aci-deploy.yaml.template > aci-deploy.yaml

az container create \
  --resource-group "$RESOURCE_GROUP" \
  --file aci-deploy.yaml

echo "Aguardando containers iniciarem..."
sleep 20

az container logs --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --container-name oracle-mercadoexpress
az container logs --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --container-name api-mercadoexpress

publicIP=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_GROUP_NAME" --query ipAddress.ip --output tsv)
echo "IP público do container group: $publicIP"
echo "API disponível em: http://$publicIP:8080"
