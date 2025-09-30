# Networking
variable "azure_subnet_cidr" {
  description = "azure subnet prefixes"
  type        = string
}


variable "gcp_infra_cidr" {
  description = "CIDR Range for GCP VMs running cloudflared"
  type        = string
}

variable "gcp_warp_cidr" {
  description = "CIDR Range for GCP VMs running warp"
  type        = string
}

variable "gcp_windows_rdp_cidr" {
  description = "CIDR Range for GCP VMs running cloudflared, Windows and RDP Server"
  type        = string
}

variable "aws_private_cidr" {
  description = "AWS public subnet"
  type        = string
}
