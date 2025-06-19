# GCP Users Configuration
variable "gcp_users" {
  type = set(string)
}

variable "aws_cloudflared_count" {
  description = "number of AWS EC2 Instances"
  type        = number
}

variable "azure_vm_count" {
  description = "number of Azure VM Instances"
  type        = number
}

variable "gcp_vm_count" {
  description = "number of vm not running cloudflared"
  type        = number
}
