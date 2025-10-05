# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-10-04
# Filename: outputs.tf
# Description: This file defines the outputs for the vm -> compute module.
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

output "private_ip_address" {
  description = "The Private IP address of the deployed VM."
  value       = azurerm_network_interface.main.private_ip_address
}
