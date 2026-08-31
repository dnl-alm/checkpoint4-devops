#!/bin/bash
set -e

# ALTERE PARA SEU RM E SUA REGIÃO (Política)
rm=rm563045
resourceGroup="rg-rm563045-mercadoexpress"
location="canadacentral"
acrName="rm563045acrme"

az group create --name "$resourceGroup" --location "$location"

az provider register --namespace Microsoft.ContainerRegistry

az acr create \
    --resource-group "$resourceGroup" \
    --name "$acrName" \
    --sku Standard \
    --location "$location" \
    --public-network-enabled true \
    --admin-enabled true
