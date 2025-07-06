#==========================================================
# Ressource Group
#==========================================================
resource "azurerm_resource_group" "cloudflare_rg" {
  name     = var.azure_resource_group_name
  location = var.azure_resource_group_location

  tags = local.azure_common_tags
}


#==========================================================
# Network Interface
#==========================================================
resource "azurerm_virtual_network" "cloudflare_vnet" {
  name                = "cloudflare-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  tags = local.azure_common_tags
}

resource "azurerm_subnet" "cloudflare_subnet" {
  name                 = "cloudflare-subnet"
  resource_group_name  = azurerm_resource_group.cloudflare_rg.name
  virtual_network_name = azurerm_virtual_network.cloudflare_vnet.name
  address_prefixes     = [var.azure_subnet_cidr]
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.azure_vm_count
  name                = "public-ip-main-${count.index}"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "${count.index == 0 ? var.azure_warp_vm_name : var.azure_vm_name}-${count.index}"

  tags = local.azure_common_tags
}


# Network Interface
resource "azurerm_network_interface" "nic" {
  count               = var.azure_vm_count
  name                = "nic-main-${count.index}"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  # To enable routing on vm count 0
  ip_forwarding_enabled = count.index == 0 ? true : false

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cloudflare_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.azure_common_tags
}

#==========================================================
# Azure NAT Gateway
#==========================================================
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  name                = "nat-gateway-public-ip"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.azure_common_tags
}

resource "azurerm_nat_gateway" "cloudflare_natgw" {
  name                = "cloudflare-natgw"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name
  sku_name            = "Standard"

  tags = local.azure_common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "natgw_ip" {
  nat_gateway_id       = azurerm_nat_gateway.cloudflare_natgw.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_public_ip.id
}

#Associate NAT Gateway with Subnet
resource "azurerm_subnet_nat_gateway_association" "cloudflare_natgw_association" {
  subnet_id      = azurerm_subnet.cloudflare_subnet.id
  nat_gateway_id = azurerm_nat_gateway.cloudflare_natgw.id
}



#==========================================================
# Local Values for Azure Configuration
#==========================================================
locals {
  # Common Azure configuration
  azure_common_config = {
    location            = azurerm_resource_group.cloudflare_rg.location
    resource_group_name = azurerm_resource_group.cloudflare_rg.name
  }

  # Common user data template variables for Azure
  azure_common_user_data_vars = merge(local.global_monitoring, {
    warp_tunnel_secret_azure = module.cloudflare.azure_extracted_warp_token
  })

  # Common tags
  azure_common_tags = var.azure_default_tags

  # Common OS disk configuration
  azure_common_os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  # Common source image configuration
  azure_common_source_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Common timeouts
  azure_common_timeouts = {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

#==========================================================
# Azure Virtual Machine
#==========================================================
resource "azurerm_linux_virtual_machine" "cloudflare_zero_trust_demo_azure" {
  count               = var.azure_vm_count
  name                = "${count.index == 0 ? var.azure_warp_vm_name : var.azure_vm_name}-${count.index}"
  resource_group_name = local.azure_common_config.resource_group_name
  location            = local.azure_common_config.location
  size                = var.azure_vm_size
  admin_username      = var.azure_vm_admin_username
  #  admin_password                  = var.azure_vm_admin_password
  #  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.azure_vm_admin_username
    public_key = module.ssh_keys.azure_ssh_public_key[count.index]
  }

  # VM index 0 = warp_connector, others = basic
  custom_data = base64encode(templatefile("${path.module}/scripts/azure-init.tftpl", merge(local.azure_common_user_data_vars, {
    role     = count.index == 0 ? "warp_connector" : "basic"
    hostname = count.index == 0 ? "${var.azure_warp_vm_name}-${count.index}" : "${var.azure_vm_name}-${count.index}"
  })))

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

  tags = local.azure_common_tags

  timeouts {
    create = local.azure_common_timeouts.create
    update = local.azure_common_timeouts.update
    delete = local.azure_common_timeouts.delete
  }
}


#==========================================================
# Routing Setup for WARP Connector
#==========================================================
resource "azurerm_route_table" "cloudflare_route_table_warp" {
  name                = "cloudflare-route-table-to-WARP"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  route {
    name                   = "route-to-warp-subnet"
    address_prefix         = var.cf_warp_cgnat_cidr # WARP subnet CIDR
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic[0].private_ip_address
  }

  route {
    name                   = "route-to-gcp-subnet"
    address_prefix         = var.gcp_warp_cidr # GCP subnet CIDR for WARP VM
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic[0].private_ip_address
  }

  route {
    name                   = "route-to-aws-subnet"
    address_prefix         = var.aws_private_cidr # AWS subnet CIDR
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic[0].private_ip_address
  }

  tags = local.azure_common_tags
}

resource "azurerm_subnet_route_table_association" "cloudflare_subnet_route_association" {
  subnet_id      = azurerm_subnet.cloudflare_subnet.id
  route_table_id = azurerm_route_table.cloudflare_route_table_warp.id


  depends_on = [azurerm_network_interface.nic] # Wait for NICs to be destroyed first
}


#==========================================================
# Connect security group to network interface 
#==========================================================
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.azure_vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_linux_virtual_machine.cloudflare_zero_trust_demo_azure] # Ensure NIC is destroyed before NSG association
}




#==========================================================
# Network Security Group
#==========================================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ssh-and-icmp-from-myIP-allowed"
  location            = local.azure_common_config.location
  resource_group_name = local.azure_common_config.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.cf_warp_cgnat_cidr
    destination_address_prefix = "*"
  }

  # Allow ping from Cloudflare WARP CGNAT range
  security_rule {
    name                       = "AllowPingInbound_WARP_client"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.cf_warp_cgnat_cidr
    destination_address_prefix = "*"
  }

  # Allow ping from GCP WARP Subnet
  security_rule {
    name                       = "AllowPingInbound_GCP_WARP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.gcp_warp_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPingOutbound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    azurerm_network_interface.nic, # Ensure NICs are destroyed before NSG
    azurerm_subnet_route_table_association.cloudflare_subnet_route_association,
  ]

  tags = local.azure_common_tags
}
