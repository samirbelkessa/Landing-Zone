resource "azurerm_management_lock" "vnet" {
  provider = azurerm.spoke

  scope      = azurerm_virtual_network.this.id
  notes      = "Prevent accidental deletion of spoke VNet ${azurerm_virtual_network.this.name}."
  name       = "${azurerm_virtual_network.this.name}-delete"
  lock_level = "CanNotDelete"
  count      = var.enable_delete_lock ? 1 : 0
}

