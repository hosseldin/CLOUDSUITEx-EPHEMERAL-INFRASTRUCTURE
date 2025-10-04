# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-10-04
# Filename: main.tf
# Description: This file contains the main Terraform configuration to deploy an Azure Linux VM with a public IP.
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

# 1. RESOURCE GROUP MODULE (The Container)
module "resource_group" {
  source = "./modules/resource_group"

  name     = "${var.project_prefix}-rg"
  location = var.location
}

# 2. NETWORK MODULE (The Foundation)
module "network" {
  source = "./modules/network"

  # Inputs from Root and RG Module
  resource_group_name = module.resource_group.name # ⬅️ Passing RG Output
  location            = module.resource_group.location

  vnet_cidr    = "10.0.0.0/16"
  subnet_cidrs = ["10.0.1.0/24"]
  subnet_names = ["vm-subnet"]
}

# 3. VM MODULE (The Compute)
module "linux_vm" {
  source = "./modules/compute/vm"

  # Inputs from RG and Network Modules
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.network.subnet_ids["vm-subnet"] # ⬅️ Passing Subnet ID Output

  # Inputs from Root Variables
  vm_name        = "${var.project_prefix}-vm-01"
  vm_size        = "Standard_B1s"
  admin_username = "vmadmin"
  admin_password = var.vm_admin_password
}
