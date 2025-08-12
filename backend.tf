terraform {
  backend "azurerm" {
    resource_group_name  = "bmw-demo-rg"
    storage_account_name = "testbmw1234storage"
    container_name       = "tfstate"
    key                  = "bmw-test.tfstate"
  }
}
