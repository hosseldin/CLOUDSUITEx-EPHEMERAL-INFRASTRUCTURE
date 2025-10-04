# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-10-04
# Filename: variables.tf
# Description: This file defines the input variables for the Terraform configuration.
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

variable "location" {
  description = "The Azure region for all resources (e.g., eastus)."
  type        = string
  default     = "East US"
}

variable "project_prefix" {
  description = "A unique prefix for naming all resources."
  type        = string
  default     = "tf-hosa"
}

variable "vm_admin_password" {
  description = "Administrator password for the Linux VM."
  type        = string
  sensitive   = true # Essential for passwords
}
