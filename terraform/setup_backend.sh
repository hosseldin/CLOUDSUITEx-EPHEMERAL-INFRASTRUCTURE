#!/bin/bash

# Configuration from your backend.tf file
RG_NAME="tf-state-rg"
SA_NAME="tfstatelocker"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "Starting Azure Backend Setup for Terraform State..."

# -----------------------------------------------------------------------------
# 1. Create Resource Group (Idempotent)
# -----------------------------------------------------------------------------
echo "Checking for Resource Group: $RG_NAME..."
if az group show --name $RG_NAME &>/dev/null; then
  echo "Resource Group '$RG_NAME' already exists."
else
  echo "Creating Resource Group '$RG_NAME' in '$LOCATION'..."
  az group create --name $RG_NAME --location $LOCATION --output none
  if [ $? -eq 0 ]; then
    echo "Resource Group created successfully."
  else
    echo "Error creating Resource Group. Exiting."
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# 2. Create Storage Account (Idempotent)
# -----------------------------------------------------------------------------
echo "Checking for Storage Account: $SA_NAME..."
if az storage account show --name $SA_NAME --resource-group $RG_NAME &>/dev/null; then
  echo "Storage Account '$SA_NAME' already exists."
else
  echo "Creating Storage Account '$SA_NAME'..."
  # Note: Storage Account names must be globally unique! 
  # If this fails, try a more unique name.
  az storage account create \
    --name $SA_NAME \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false \
    --output none
  
  if [ $? -eq 0 ]; then
    echo "Storage Account created successfully."
  else
    echo "Error creating Storage Account. Exiting. (Check name uniqueness)."
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# 3. Create Blob Container (Idempotent)
# -----------------------------------------------------------------------------
echo "Checking for Blob Container: $CONTAINER_NAME..."

# To check container existence, we need the Storage Account Key
SA_KEY=$(az storage account keys list --resource-group $RG_NAME --account-name $SA_NAME --query '[0].value' -o tsv)

# Check if the container exists using the key for authentication
if az storage container show \
  --name $CONTAINER_NAME \
  --account-name $SA_NAME \
  --account-key $SA_KEY &>/dev/null; then
  
  echo "Blob Container '$CONTAINER_NAME' already exists."
else
  echo "Creating Blob Container '$CONTAINER_NAME'..."
  az storage container create \
    --name $CONTAINER_NAME \
    --account-name $SA_NAME \
    --account-key $SA_KEY \
    --public-access off \
    --output none
  echo "Blob Container created successfully."
fi

echo "Backend setup complete. You can now run 'terraform init'."