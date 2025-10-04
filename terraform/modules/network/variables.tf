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
  description = "Name of the Resource Group to place the VNet."
  type        = string
}

variable "location" {
  description = "The Azure region."
  type        = string
}

variable "vnet_cidr" {
  description = "The CIDR block for the VNet (e.g., 10.0.0.0/16)."
  type        = string
}

variable "subnet_cidrs" {
  description = "A list of CIDR blocks for the subnets."
  type        = list(string)
}

variable "subnet_names" {
  description = "A list of names for the subnets."
  type        = list(string)
}
