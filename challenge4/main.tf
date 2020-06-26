terraform {
  backend "azurerm" {
    resource_group_name   = "tf-state"
    storage_account_name  = "hconf2020tfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}


provider "azurerm" {
    version         = "~>2.14.0"
    features {}
}


resource "azurerm_resource_group" "main" {
    name            = "resources-${var.env_prefix}"
    location        = var.location
}

resource "azurerm_container_registry" "main" {
  name                     = "acr${var.env_prefix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  sku                      = "Standard"
  admin_enabled            = false
}


resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.env_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${var.env_prefix}"

  default_node_pool {
    name       = "main"
    node_count = var.k8s_node_count
    vm_size    = var.k8s_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

#Configure ACR integration for existing AKS clusters
resource "null_resource" "attachacr" {
    provisioner "local-exec" {
        command = "az aks update -n ${azurerm_kubernetes_cluster.main.name} -g ${azurerm_resource_group.main.name} --attach-acr ${azurerm_container_registry.main.name}"
    }
    depends_on = [azurerm_kubernetes_cluster.main]
}

