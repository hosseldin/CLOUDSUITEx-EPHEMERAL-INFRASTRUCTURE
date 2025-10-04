# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-10-04
# Filename: outputs.tf
# Description: This file defines the outputs for the Resource Group module.
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

output "name" {
  description = "The name of the Resource Group created."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "The location of the Resource Group."
  value       = azurerm_resource_group.main.location
}
