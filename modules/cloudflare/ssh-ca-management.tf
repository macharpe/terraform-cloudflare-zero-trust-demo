#==========================================================
# SSH CA Management
#==========================================================
# This file handles the SSH Certificate Authority operations
# including DELETE and POST operations to reset the SSH CA

# Reset SSH CA and capture public key
resource "null_resource" "cloudflare_ssh_ca_reset" {
  triggers = {
    account_id = var.cloudflare_account_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Delete existing SSH CA
      curl "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/access/gateway_ca" \
        --request DELETE \
        --header "Authorization: Bearer ${var.cloudflare_api_token}" \
        --silent || true

      # Wait a moment for deletion to complete
      sleep 2

      # Create new SSH CA and capture response
      RESPONSE=$(curl "https://api.cloudflare.com/client/v4/accounts/${var.cloudflare_account_id}/access/gateway_ca" \
        --request POST \
        --header "Authorization: Bearer ${var.cloudflare_api_token}" \
        --silent)

      # Create output directory
      mkdir -p ${path.module}/out

      # Extract public_key and store it in a file
      echo "$RESPONSE" | jq -r '.result.public_key // empty' > ${path.module}/out/ssh_ca_public_key.txt
      chmod 600 ${path.module}/out/ssh_ca_public_key.txt

      # Also store the full response for reference
      echo "$RESPONSE" > ${path.module}/out/ssh_ca_response.json
      chmod 600 ${path.module}/out/ssh_ca_response.json
    EOT
  }
}

# Read the stored public key
data "external" "ssh_ca_public_key" {
  depends_on = [null_resource.cloudflare_ssh_ca_reset]
  
  program = ["sh", "-c", "cat ${path.module}/out/ssh_ca_public_key.txt 2>/dev/null | jq -R '{public_key: .}' || echo '{\"public_key\": \"\"}'"]
}

# For backward compatibility, simulate the original http data source structure
locals {
  gateway_ca_certificate = {
    result = {
      public_key = data.external.ssh_ca_public_key.result.public_key
    }
  }
}