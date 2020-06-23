provider "azurerm" {
    version         = "~>2.14.0"
    subscription_id = var.subscription_id
    features {}
}


resource "azurerm_resource_group" "main" {
    name            = "resources-${var.env_prefix}"
    location        = var.location
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
        "ApiUrl"                        = ""
        "ApiUrlShoppingCart"            = ""
        "MongoConnectionString"         = ""
        "SqlConnectionString"           = ""
        "productImagesUrl"              = "https://raw.githubusercontent.com/microsoft/TailwindTraders-Backend/master/Deploy/tailwindtraders-images/product-detail"
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