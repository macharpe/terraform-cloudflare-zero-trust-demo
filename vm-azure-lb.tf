#==========================================================
# Load Balancing Demo - Azure VM (DR Site)
# VM Name: cloudflare-lb-demo-dr-azure
#==========================================================
# This file creates an Azure Linux VM for the Load Balancing demo.
# The VM runs nginx serving the Swiss Insurance website and is
# connected to Cloudflare via a cloudflared tunnel.
# This instance simulates a "Disaster Recovery" site.
#
# Uses a separate subnet with NAT Gateway (no WARP routing interference)
# More cost-effective than dedicated Public IP
#
# To remove: Delete this file and run terraform apply
#==========================================================

#==========================================================
# Separate Subnet for LB Demo (no WARP routing)
#==========================================================
resource "azurerm_subnet" "azure_subnet_lb_demo" {
  count                = var.lb_demo_enabled ? 1 : 0
  name                 = "cloudflare-subnet-lb-demo"
  resource_group_name  = azurerm_resource_group.cloudflare_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet_main.name
  address_prefixes     = ["192.168.72.0/24"]
}

#==========================================================
# Associate NAT Gateway with LB Demo Subnet
#==========================================================
resource "azurerm_subnet_nat_gateway_association" "lb_demo_natgw_association" {
  count          = var.lb_demo_enabled ? 1 : 0
  subnet_id      = azurerm_subnet.azure_subnet_lb_demo[0].id
  nat_gateway_id = azurerm_nat_gateway.cloudflare_natgw.id

  # Ensure NAT Gateway has public IP before associating
  depends_on = [azurerm_nat_gateway_public_ip_association.natgw_ip]
}

#==========================================================
# Network Interface for LB Azure Instance
#==========================================================
resource "azurerm_network_interface" "lb_demo_nic" {
  count               = var.lb_demo_enabled ? 1 : 0
  name                = "nic-lb-demo"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure_subnet_lb_demo[0].id
    private_ip_address_allocation = "Dynamic"
    # No public IP - uses NAT Gateway for outbound
  }

  tags = merge(local.azure_common_tags, {
    Purpose = "LB Demo DR Site"
  })
}

#==========================================================
# Network Security Group for LB Demo Instance
#==========================================================
resource "azurerm_network_security_group" "lb_demo_nsg" {
  count               = var.lb_demo_enabled ? 1 : 0
  name                = "nsg-lb-demo"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  # Allow SSH from WARP CGNAT range (for troubleshooting)
  security_rule {
    name                       = "AllowSSH_WARP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.cf_warp_cgnat_cidr
    destination_address_prefix = "*"
  }

  # Allow HTTP from within VNet (cloudflared tunnel traffic)
  security_rule {
    name                       = "AllowHTTP_VNet"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.lb_web_port)
    source_address_prefix      = var.azure_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow ICMP (ping) from WARP
  security_rule {
    name                       = "AllowICMP_WARP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.cf_warp_cgnat_cidr
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(local.azure_common_tags, {
    Purpose = "LB Demo DR Site"
  })
}

#==========================================================
# Associate NSG with NIC
#==========================================================
resource "azurerm_network_interface_security_group_association" "lb_demo_nsg_assoc" {
  count                     = var.lb_demo_enabled ? 1 : 0
  network_interface_id      = azurerm_network_interface.lb_demo_nic[0].id
  network_security_group_id = azurerm_network_security_group.lb_demo_nsg[0].id
}

#==========================================================
# Azure Linux VM: Load Balancing Demo - DR Site
#==========================================================
resource "azurerm_linux_virtual_machine" "azure_vm_lb_demo" {
  count               = var.lb_demo_enabled ? 1 : 0
  name                = var.lb_azure_vm_name
  resource_group_name = local.azure_common_config.resource_group_name
  location            = local.azure_common_config.location
  size                = var.azure_vm_size
  admin_username      = var.azure_vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.lb_demo_nic[0].id
  ]

  admin_ssh_key {
    username   = var.azure_vm_admin_username
    public_key = module.ssh_keys.azure_lb_demo_public_key
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init/azure-lb-init.tftpl", {
    hostname             = var.lb_azure_vm_name
    lb_web_port          = var.lb_web_port
    tunnel_token         = module.cloudflare.lb_azure_tunnel_token
    swiss_insurance_html = file("${path.module}/scripts/html/swiss-insurance.html")
    datadog_api_key      = var.datadog_api_key
    datadog_region       = var.datadog_region
  }))

  os_disk {
    caching              = local.azure_common_os_disk.caching
    storage_account_type = local.azure_common_os_disk.storage_account_type
    disk_size_gb         = local.azure_common_os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = local.azure_common_source_image.publisher
    offer     = local.azure_common_source_image.offer
    sku       = local.azure_common_source_image.sku
    version   = local.azure_common_source_image.version
  }

  tags = merge(local.azure_common_tags, {
    Purpose = "LB Demo DR Site"
  })

  timeouts {
    create = local.azure_common_timeouts.create
    update = local.azure_common_timeouts.update
    delete = local.azure_common_timeouts.delete
  }
}
