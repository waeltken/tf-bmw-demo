provider "azurerm" {
  features {}
}

variable "prefix" {
  default     = "bmw"
  description = "Prefix for all resources in this configuration."
}

variable "admin_username" {
  default     = "azureuser"
  description = "The username for the admin account on the VM."
}

variable "accept_agreement" {
  default = true
}

resource "azurerm_marketplace_agreement" "audiocodes" {
  count     = var.accept_agreement ? 1 : 0
  publisher = "audiocodes"
  offer     = "mediantsessionbordercontroller"
  plan      = "mediantvesbcazure"
}

locals {
  vm_name = "${var.prefix}-vm"
}

resource "azurerm_resource_group" "demo" {
  name     = "${var.prefix}-demo-rg"
  location = "germanywestcentral"
  tags = {
  }
}

resource "azurerm_storage_account" "state" {
  name                            = "test${var.prefix}1234storage"
  location                        = azurerm_resource_group.demo.location
  resource_group_name             = azurerm_resource_group.demo.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_network_security_group" "internal" {
  name                = "${var.prefix}-internal-nsg"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.internal.id
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "audiocodes_vm1" {
  source              = "./modules/virtualmachine"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  subnet_id           = azurerm_subnet.internal.id
}

module "audiocodes_vm2" {
  source              = "./modules/virtualmachine"
  location            = azurerm_resource_group.demo.location
  prefix              = "bmw2"
  resource_group_name = azurerm_resource_group.demo.name
  subnet_id           = azurerm_subnet.internal.id
}

output "initial_admin_passwords" {
  sensitive = true
  value = [
    module.audiocodes_vm1.initial_admin_password,
    module.audiocodes_vm2.initial_admin_password
  ]
}
