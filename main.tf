provider "azurerm" {
  subscription_id = "eedea4b7-9139-440d-84b1-0b09522f109e"
  features {}
}

resource "azurerm_resource_group" "demo" {
  name     = "bmw-demo-rg"
  location = "germanywestcentral"
  tags = {
  }
}


data "azurerm_virtual_network" "aks" {
  name                = "aks-vnet"
  resource_group_name = "aks-dev"
}

output "vnetinfo" {
  value = data.azurerm_virtual_network.aks
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
