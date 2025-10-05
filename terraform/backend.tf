# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-10-05
# Filename: backend.tf
# Description: Terraform backend configuration for storing state in Azure Blob Storage.
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

terraform {
  backend "azurerm" {
    # These values must be created manually in Azure first
    resource_group_name  = "tf-state-rg"
    storage_account_name = "tfstatelocker"
    container_name       = "tfstate"
    key                  = "vm-deployment.tfstate"
  }
  // ... required_providers block follows
}

