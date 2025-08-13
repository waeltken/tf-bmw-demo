variable "prefix" {
  default = "bmw"
}

locals {
  vm_name = "${var.prefix}-vm"
}

variable "admin_username" {
  description = "The admin username for the virtual machine"
  default     = "azureuser"
}

variable "location" {
}

variable "resource_group_name" {
}

variable "subnet_id" {
}

resource "random_password" "admin_password" {
  length  = 24
  special = true
}

resource "azurerm_public_ip" "main" {
  allocation_method   = "Static"
  name                = "${var.prefix}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}


resource "azurerm_virtual_machine" "audiocodes" {
  name                  = local.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
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
}

output "initial_admin_password" {
  sensitive = true
  value     = random_password.admin_password.result
}
