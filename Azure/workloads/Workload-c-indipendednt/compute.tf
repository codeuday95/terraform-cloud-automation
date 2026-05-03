# =============================================================================
# Primary Virtual Machine
# =============================================================================
module "vm_primary" {
  source               = "../../modules/linux_vm"
  vm_name              = "vm-${var.workload_name}-${var.primary_location}"
  resource_group_name  = module.rg_primary.name
  location             = module.rg_primary.location
  subnet_id            = module.vnet_primary.subnets["snet-web"].id
  admin_username       = azurerm_key_vault_secret.vm_username.value
  admin_ssh_public_key = tls_private_key.vm_ssh.public_key_openssh
  nsg_name             = "nsg-${var.workload_name}-pri"
  key_vault_id         = module.key_vault.id
  
  vm_size              = "Standard_B2s"
  tags                 = var.tags

  depends_on = [module.rg_primary]
}

# Attach VM to Application Gateway backend pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "vm_agw" {
  network_interface_id    = module.vm_primary.nic_id
  ip_configuration_name   = "internal" # Standard configuration name in typical linux_vm modules
  backend_address_pool_id = module.appgw_primary.backend_address_pool_id
}

# =============================================================================
# Application Deployment (Custom Script Extension -> Dynamic Python App)
# =============================================================================
resource "azurerm_virtual_machine_extension" "app_setup" {
  name                 = "app-setup"
  virtual_machine_id   = module.vm_primary.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  # Deploy a Python HTTP server that queries IMDS for compute location, and uses pymssql to query real-time SQL Failover Data!
  settings = jsonencode({
    "commandToExecute" = <<EOT
apt-get update && apt-get install -y python3-pip
pip3 install pymssql

cat << 'EOF' > /opt/app.py
import http.server
import socketserver
import pymssql
import urllib.request
import json
import os

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        
        # 1. Fetch VM Location data
        try:
            req = urllib.request.Request("http://169.254.169.254/metadata/instance?api-version=2021-02-01", headers={"Metadata": "true"})
            with urllib.request.urlopen(req, timeout=2) as response:
                imds = json.loads(response.read().decode())
        except Exception:
            imds = {"compute": {"name": "Unknown", "location": "Unknown"}}

        # 2. Test Database Connection and fetch Active Replica Server Name
        try:
            conn = pymssql.connect(
                server="${azurerm_mssql_failover_group.fog.name}.database.windows.net", 
                user="${azurerm_key_vault_secret.sql_username.value}", 
                password="${azurerm_key_vault_secret.sql_password.value}", 
                database="db-${var.workload_name}",
                login_timeout=5
            )
            cursor = conn.cursor()
            cursor.execute("SELECT @@SERVERNAME")
            db_server = cursor.fetchone()[0]
            conn.close()
            db_status = f"<span style='color:green;'><b>SUCCESS</b> - Master Replica Active: <b>{db_server}</b></span>"
        except Exception as e:
            db_status = f"<span style='color:red;'><b>Database Connection Failed:</b> {str(e)}</span>"

        # 3. Render HTML
        html = f"""<html>
        <head><style>body{{font-family: sans-serif; background-color: #f4f4f9; text-align: center; padding: 50px;}} h1{{color: #005A9E;}} .box{{background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); display: inline-block;}}</style></head>
        <body>
          <div class="box">
            <h1>DR Verification Dashboard</h1>
            <hr>
            <h3>Compute Diagnostics</h3>
            <p>Physical VM: <strong>{imds['compute']['name']}</strong></p>
            <p>Running in Azure Region: <strong>{imds['compute']['location']}</strong></p>
            <hr>
            <h3>Real-Time Database Verification</h3>
            <p>Hitting FQDN: <strong>${azurerm_mssql_failover_group.fog.name}.database.windows.net</strong></p>
            <p>{db_status}</p>
          </div>
        </body>
        </html>"""
        
        self.wfile.write(html.encode("utf-8"))

with socketserver.TCPServer(("", 80), Handler) as httpd:
    httpd.serve_forever()
EOF

# Kill any existing web servers and setup systemd service
systemctl stop nginx || true
cat << 'EOF' > /etc/systemd/system/drtester.service
[Unit]
Description=DR Tester Python App
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable drtester
systemctl restart drtester
EOT
  })

  depends_on = [
    module.vm_primary,
    azurerm_mssql_failover_group.fog,
    azurerm_key_vault_secret.sql_username,
    azurerm_key_vault_secret.sql_password
  ]
}
