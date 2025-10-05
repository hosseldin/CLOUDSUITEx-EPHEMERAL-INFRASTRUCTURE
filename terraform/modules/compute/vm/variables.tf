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

variable "resource_group_name" {
  description = "Name of the Resource Group."
  type        = string
}

variable "location" {
  description = "The Azure region."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the Subnet the VM will be placed in."
  type        = string
}

variable "vm_name" {
  description = "The name for the VM and its resources."
  type        = string
}

variable "vm_size" {
  description = "The size of the VM (e.g., Standard_B1s)."
  type        = string
}

variable "admin_username" {
  description = "The administrator username for the VM."
  type        = string
}

variable "admin_password" {
  description = "The administrator password for the VM."
  type        = string
  sensitive   = true
}
