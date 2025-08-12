provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "demo" {
  name     = "bmw-demo-rg"
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
