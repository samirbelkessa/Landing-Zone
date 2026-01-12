# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Main - F00 Terraform Backend                                                  ║
# ║ Simple Storage Account for centralized Terraform state files                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ─────────────────────────────────────────────────────────────────────────────────
# Storage Account
# ─────────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant for state files safety
  min_tls_version          = "TLS1_2"

  # State files don't need hierarchical namespace
  is_hns_enabled = false

  # Prevent accidental deletion
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true  # Keep history of state files

    delete_retention_policy {
      days = 30  # Recover deleted state files
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────────
# Blob Container
# ─────────────────────────────────────────────────────────────────────────────────

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
