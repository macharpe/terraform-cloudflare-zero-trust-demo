################### SSH KEY #######################


# =========================
#         GCP
# =========================

# Generate SSH keys for GCP users on Infrastructure Access Instance
resource "tls_private_key" "gcp_user_keys" {
  for_each = var.gcp_users
  #algorithm = "ED25519"
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "gcp_private_keys" {
  for_each = var.gcp_users

  content         = tls_private_key.gcp_user_keys[each.key].private_key_pem
  filename        = "${path.module}/out/gcp_ssh_${each.key}"
  file_permission = "0600"
}

resource "local_file" "gcp_public_keys" {
  for_each = var.gcp_users

  content         = tls_private_key.gcp_user_keys[each.key].public_key_openssh
  filename        = "${path.module}/out/gcp_ssh_${each.key}.pub"
  file_permission = "0600"
}


# Generate SSH keys for GCP VM Instances
resource "tls_private_key" "gcp_vm_key" {
  count = var.gcp_vm_count
  #algorithm = "ED25519"
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "gcp_vm_private_key" {
  count           = var.gcp_vm_count
  content         = tls_private_key.gcp_vm_key[count.index].private_key_pem
  filename        = "${path.module}/out/gcp_vm_key_pair_${count.index}"
  file_permission = "0600"
}

resource "local_file" "gcp_vm_public_key" {
  count           = var.gcp_vm_count
  content         = tls_private_key.gcp_vm_key[count.index].public_key_openssh
  filename        = "${path.module}/out/gcp_vm_key_pair_${count.index}.pub"
  file_permission = "0600"
}




# =========================
#         AWS
# =========================
# AWS Key Pairs for Cloudflared (separate configuration)
resource "tls_private_key" "aws_ssh_key" {
  count     = var.aws_ec2_cloudflared_replica_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "aws_private_key" {
  count           = var.aws_ec2_cloudflared_replica_count
  content         = tls_private_key.aws_ssh_key[count.index].private_key_pem
  filename        = "${path.module}/out/aws_ssh_cloudflared_key_pair_${count.index}"
  file_permission = "0600"
}

resource "local_file" "aws_public_key" {
  count           = var.aws_ec2_cloudflared_replica_count
  content         = tls_private_key.aws_ssh_key[count.index].public_key_openssh
  filename        = "${path.module}/out/aws_ssh_cloudflared_key_pair_${count.index}.pub"
  file_permission = "0600"
}


# AWS Key Pair for SERVICE VM
resource "tls_private_key" "aws_ssh_service_key" {
  #algorithm = "ED25519"
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "aws_service_private_key" {
  content         = tls_private_key.aws_ssh_service_key.private_key_pem
  filename        = "${path.module}/out/aws_ssh_service_key_pair"
  file_permission = "0600"
}

resource "local_file" "aws_service_public_key" {
  content         = tls_private_key.aws_ssh_service_key.public_key_openssh
  filename        = "${path.module}/out/aws_ssh_service_key_pair.pub"
  file_permission = "0600"
}

# AWS Key Pair for SERVICE VNC VM
resource "tls_private_key" "aws_vnc_service_key" {
  #algorithm = "ED25519"
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "aws_vnc_private_key" {
  content         = tls_private_key.aws_vnc_service_key.private_key_pem
  filename        = "${path.module}/out/aws_vnc_service_key_pair"
  file_permission = "0600"
}

resource "local_file" "aws_vnc_public_key" {
  content         = tls_private_key.aws_vnc_service_key.public_key_openssh
  filename        = "${path.module}/out/aws_vnc_service_key_pair.pub"
  file_permission = "0600"
}



# =========================
#         Azure
# =========================
# Azure Key Pair for VM
resource "tls_private_key" "azure_ssh_key" {
  count     = var.azure_vm_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "azure_private_key" {
  count           = var.azure_vm_count
  content         = tls_private_key.azure_ssh_key[count.index].private_key_pem
  filename        = "${path.module}/out/azure_ssh_key_pair_${count.index}"
  file_permission = "0600"
}

resource "local_file" "azure_public_key" {
  count           = var.azure_vm_count
  content         = tls_private_key.azure_ssh_key[count.index].public_key_openssh
  filename        = "${path.module}/out/azure_ssh_key_pair_${count.index}.pub"
  file_permission = "0600"
}
