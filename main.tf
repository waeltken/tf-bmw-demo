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

locals {
  vm_name = "${var.prefix}-vm"
}

resource "random_password" "admin_password" {
  length  = 24
  special = true
}

resource "azurerm_resource_group" "demo" {
  name     = "${var.prefix}-demo-rg"
  location = "germanywestcentral"
  tags = {
  }
}

resource "azurerm_storage_account" "state" {
  name                            = "testbmw1234storage"
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

resource "azurerm_public_ip" "main" {
  allocation_method   = "Static"
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_marketplace_agreement" "audiocodes" {
  publisher = "audiocodes"
  offer     = "mediantsessionbordercontroller"
  plan      = "mediantvesbcazure"
}

resource "azurerm_virtual_machine" "audiocodes" {
  name                  = local.vm_name
  location              = azurerm_resource_group.demo.location
  resource_group_name   = azurerm_resource_group.demo.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "audiocodes"
    offer     = "mediantsessionbordercontroller"
    sku       = "mediantvesbcazure"
    version   = "latest"
  }

  plan {
    name      = "mediantvesbcazure"
    product   = "mediantsessionbordercontroller"
    publisher = "audiocodes"
  }


  os_profile {
    admin_username = var.admin_username
    admin_password = random_password.admin_password.result
    computer_name  = "ubuntu"
  }

  storage_os_disk {
    name          = "${local.vm_name}-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [azurerm_marketplace_agreement.audiocodes]
}

output "initial_admin_password" {
  sensitive = true
  value     = random_password.admin_password.result
}
