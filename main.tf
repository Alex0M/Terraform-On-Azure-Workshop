provider "azurerm" {
    version         = "~>2.14.0"
    subscription_id = var.subscription_id
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

resource "azurerm_storage_account" "main" {
  name                     = "dbsa${var.env_prefix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_database" "main" {
  name                = "sqldb-${var.env_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.main.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.main.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.main.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }
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

resource "azurerm_app_service_plan" "main" {
    name                = "asp-${var.env_prefix}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    kind                = "Windows"

    sku {
        tier = "Standard"
        size = "S1"
    }
}

resource "azurerm_app_service" "main" {
    name                = "webappservice-${var.env_prefix}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    app_service_plan_id = azurerm_app_service_plan.main.id

    site_config {
        always_on           = true
        default_documents   = [
            "Default.htm",
            "Default.html"
        ]
    }

    app_settings = {
        "WEBSITE_NODE_DEFAULT_VERSION"  = "10.15.2"
        "ApiUrl"                        = "/api/v1"
        "ApiUrlShoppingCart"            = "/api/v1"
        "MongoConnectionString"         = "mongodb://${var.mongo_root_user}:${var.mongo_root_pass}@${azurerm_container_group.main.fqdn}:27017"
        "SqlConnectionString"           = "Server=tcp:${azurerm_sql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.main.name};Persist Security Info=False;User ID=${var.sqlserver_login};Password=${var.sqlserver_pass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        "productImagesUrl"              = "https://raw.githubusercontent.com/suuus/TailwindTraders-Backend/master/Deploy/tailwindtraders-images/product-detail"
        "Personalizer__ApiKey"          = ""
        "Personalizer__Endpoint"        = ""
    }
}


resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "az webapp deployment source config --branch ${var.branch} --manual-integration --name ${azurerm_app_service.main.name} --repo-url ${var.repo_url} --resource-group ${azurerm_resource_group.main.name}"
  }

  depends_on = [
    azurerm_app_service.main,
  ]
}