#!/bin/bash

# Get the script directory to find terraform.tfvars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_TFVARS="$SCRIPT_DIR/../../../terraform.tfvars"

# Cloudflare API Details
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID}"
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN}"

# Extract rule ID from terraform.tfvars
RULE_ID=$(grep "cf_osx_version_posture_rule_id" "$TERRAFORM_TFVARS" | sed 's/.*= *"\([^"]*\)".*/\1/')

# Fetch latest macOS version
# Note: Using -k flag due to WARP SSL inspection. Add gdmf.apple.com to WARP "Do Not Inspect" list to remove -k
LATEST_VERSION=$(curl -s -k https://gdmf.apple.com/v2/pmv | jq -r '.PublicAssetSets.macOS[] | .ProductVersion' | sort -V | tail -n 1 | sed -E 's/^([0-9]+\.[0-9]+)$/\1.0/')

# Update Cloudflare Device Posture rule
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/devices/posture/$RULE_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"input\": {
        \"version\": \"$LATEST_VERSION\",
        \"operator\": \">=\"
      },
      \"match\": [
        {
          \"platform\": \"mac\"
        }
      ],
      \"schedule\": \"5m\",
      \"id\": \"$RULE_ID\",
      \"type\": \"os_version\",
      \"description\": \"Check for latest macOS version\",
      \"name\": \"macOS Version Rule\",
      \"expiration\": null
    }"

