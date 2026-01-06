provider "azurerm" {
  subscription_id = "ef7442e9-4d15-4a28-939a-f428a3d59487"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
