# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Outputs - F00 Terraform Backend                                               ║
# ║ All values needed to configure backend blocks in other modules                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group containing the state storage."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID of the resource group."
  value       = azurerm_resource_group.this.id
}

# ─────────────────────────────────────────────────────────────────────────────────
# Storage Account
# ─────────────────────────────────────────────────────────────────────────────────

output "storage_account_name" {
  description = "Name of the storage account for backend configuration."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

# ─────────────────────────────────────────────────────────────────────────────────
# Container
# ─────────────────────────────────────────────────────────────────────────────────

output "container_name" {
  description = "Name of the blob container for tfstate files."
  value       = azurerm_storage_container.this.name
}

output "container_id" {
  description = "ID of the blob container."
  value       = azurerm_storage_container.this.id
}

# ─────────────────────────────────────────────────────────────────────────────────
# Backend Config Helper
# ─────────────────────────────────────────────────────────────────────────────────

output "backend_config" {
  description = "Complete backend configuration to use in other modules."
  value = {
    resource_group_name  = azurerm_resource_group.this.name
    storage_account_name = azurerm_storage_account.this.name
    container_name       = azurerm_storage_container.this.name
  }
}
