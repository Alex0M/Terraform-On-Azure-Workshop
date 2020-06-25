#!/bin/bash

read -sp 'Subscription ID: ' SUBSCRIPTION_ID
read -p 'Service Principal Name: ' SP_NAME

if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Subscription ID must be specified"
    exit 1
fi

if [ -z "$SP_NAME" ]; then
    echo "Service Principal Name must be specified"
    exit 1
fi

RESOURCE_GROUP_NAME=tf-state
STORAGE_ACCOUNT_NAME=hconf2020tfstate
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "access_key: $ACCOUNT_KEY"

# Create Service Principal for Terraform
az ad sp create-for-rbac --role="Contributor" --name=$SP_NAME --scopes="/subscriptions/$SUBSCRIPTION_ID"