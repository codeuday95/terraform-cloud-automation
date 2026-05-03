output "server_id" { value = azurerm_mssql_server.main.id }
output "server_name" { value = azurerm_mssql_server.main.name }
output "database_id" { value = try(azurerm_mssql_database.db[0].id, null) }
