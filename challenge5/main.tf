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

resource "azurerm_sql_server" "main" {
  name                         = "sqlserver-${var.env_prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sqlserver_login
  administrator_login_password = var.sqlserver_pass
}

resource "azurerm_sql_database" "main" {
  name                = "sqldb-${var.env_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.main.name
}

resource "azurerm_sql_firewall_rule" "main" {
    name                = "sqlfirewall-${var.env_prefix}"
    resource_group_name = azurerm_resource_group.main.name
    server_name         = azurerm_sql_server.main.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "0.0.0.0"
}

resource "azurerm_container_group" "main" {
  name                  = "aci-${var.env_prefix}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  ip_address_type       = "public"
  dns_name_label        = "aci-${var.env_prefix}"
  os_type               = "Linux"

  container {
    name   = "mongodb"
    image  = "mongo:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 27017
      protocol = "TCP"
    }

    environment_variables = {
        MONGO_INITDB_ROOT_USERNAME = var.mongo_root_user
        MONGO_INITDB_ROOT_PASSWORD = var.mongo_root_pass
    }
  }
}


# reate ACR
resource "azurerm_container_registry" "main" {
  name                     = "acr${var.env_prefix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  sku                      = "Standard"
  admin_enabled            = false
}


# Create a log analytics workspace
resource "azurerm_log_analytics_workspace" "logws" {
    name                = "logws-${var.env_prefix}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    sku                 = "PerGB2018"
}

# Create a log analytics solution to capture the logs from the containers on our cluster
resource "azurerm_log_analytics_solution" "logsol" {
    solution_name           = "ContainerInsights"
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name
    workspace_resource_id   = azurerm_log_analytics_workspace.logws.id
    workspace_name          = azurerm_log_analytics_workspace.logws.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

# Create an AKS cluster
resource "azurerm_kubernetes_cluster" "k8s" {
    name                    = "aks-${var.env_prefix}"
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name
    dns_prefix              = "aks-${var.env_prefix}"

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.k8s_ssh_public_key)
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.k8s_node_count
        vm_size         = var.k8s_vm_size
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    addon_profile {
        oms_agent {
            enabled                    = true
            log_analytics_workspace_id = azurerm_log_analytics_workspace.logws.id
        }
    }
}

resource "helm_release" "consul" {
  repository = "https://helm.releases.hashicorp.com"
  name       = "alexom-consul"
  chart      = "consul"

  set {
    name  = "global.name"
    value = "consul"
  }
  set {
    name  = "global.datacenter"
    value = "alexom"
  }
  set {
    name  = "server.bootstrapExpect"
    value = 1
  }
  set {
    name  = "server.replicas"
    value = 1
  }

  values = ["${file("assets/consul-federation.yaml")}"]
}

resource "kubernetes_service" "public_ip" {
  metadata {
    name = "azure-load-balancer"
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-resource-group" = azurerm_kubernetes_cluster.k8s.node_resource_group
    }
  }
  spec {
    selector = {
      app       = "consul"
      component = "mesh-gateway"
    }
    session_affinity = "ClientIP"
    port {
      port        = 8302
      target_port = 80
    }

    type = "LoadBalancer"
  }
}