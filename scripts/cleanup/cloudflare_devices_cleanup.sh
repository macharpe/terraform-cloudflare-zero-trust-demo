#!/bin/bash

# Cloudflare Zero Trust Device Cleanup Script - Terraform Compatible Version
# This script removes devices with names starting with "cloudflare-warp-connector-"
# Designed for automation/CI/CD without interactive prompts

set -euo pipefail

# Configuration
PREFIX="${PREFIX:-cloudflare-warp-connector-}"
DRY_RUN="${DRY_RUN:-true}"
FORCE_DELETE="${FORCE_DELETE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Cloudflare Zero Trust Device Cleanup Script - Terraform Compatible

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be deleted without actually deleting (default)
    -l, --live          Actually delete devices (turns off dry-run)
    -f, --force         Force deletion without confirmation (required for live mode)
    -p, --prefix PREFIX Set device name prefix to filter (default: cloudflare-warp-connector-)

ENVIRONMENT VARIABLES:
    CLOUDFLARE_EMAIL            Your Cloudflare account email (required)
    CLOUDFLARE_API_KEY          Your Cloudflare Global API Key (required)
    CLOUDFLARE_ACCOUNT_ID       Your Cloudflare account ID (required)
    PREFIX                          Device name prefix to filter (optional)
    DRY_RUN                         Set to "false" to enable live deletion (optional)
    FORCE_DELETE                    Set to "true" to skip confirmation (required for live mode)

EXAMPLES:
    # Dry run (default)
    $0

    # Actually delete devices (Terraform-friendly)
    DRY_RUN=false FORCE_DELETE=true $0

    # Actually delete devices with flags
    $0 --live --force

    # Use custom prefix
    $0 --prefix "my-connector-" --live --force
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -l|--live)
            DRY_RUN="false"
            shift
            ;;
        -f|--force)
            FORCE_DELETE="true"
            shift
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        *)
            print_color $RED "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check environment variables
if [[ -z "${CLOUDFLARE_EMAIL:-}" ]]; then
    print_color $RED "Error: CLOUDFLARE_EMAIL environment variable is required"
    exit 1
fi

if [[ -z "${CLOUDFLARE_API_KEY:-}" ]]; then
    print_color $RED "Error: CLOUDFLARE_API_KEY environment variable is required"
    exit 1
fi

if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    print_color $RED "Error: CLOUDFLARE_ACCOUNT_ID environment variable is required"
    exit 1
fi

# Check prerequisites
if ! command -v curl &> /dev/null; then
    print_color $RED "Error: curl is required but not installed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_color $RED "Error: jq is required but not installed."
    exit 1
fi

# Validate live mode requirements
if [[ "$DRY_RUN" == "false" && "$FORCE_DELETE" != "true" ]]; then
    print_color $RED "Error: Live deletion mode requires --force flag or FORCE_DELETE=true environment variable"
    print_color $YELLOW "This is required for automation to prevent hanging on confirmation prompts"
    exit 1
fi

# Show configuration
print_color $BLUE "Cloudflare Zero Trust Device Cleanup"
print_color $BLUE "=================================================="
echo "Email: $CLOUDFLARE_EMAIL"
echo "Account ID: $CLOUDFLARE_ACCOUNT_ID"
echo "Filter prefix: $PREFIX"
echo "Mode: $(if [[ "$DRY_RUN" == "true" ]]; then echo "DRY RUN"; else echo "LIVE DELETION"; fi)"
if [[ "$DRY_RUN" == "false" ]]; then
    echo "Force delete: $FORCE_DELETE"
fi
print_color $BLUE "=================================================="

# Get all devices
print_color $BLUE "Fetching devices from Cloudflare Zero Trust..."

devices_response=$(curl -s \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/devices/physical-devices")

# Check if API call was successful
if ! echo "$devices_response" | jq -e '.success' > /dev/null; then
    print_color $RED "Failed to fetch devices from API:"
    echo "$devices_response" | jq '.errors'
    exit 1
fi

# Extract devices
all_devices=$(echo "$devices_response" | jq '.result')
total_count=$(echo "$all_devices" | jq 'length')

print_color $BLUE "Total devices found: $total_count"

# Filter devices by prefix
filtered_devices=$(echo "$all_devices" | jq --arg prefix "$PREFIX" '[.[] | select(.name | startswith($prefix))]')
filtered_count=$(echo "$filtered_devices" | jq 'length')

print_color $BLUE "Devices matching prefix '$PREFIX': $filtered_count"

if [[ $filtered_count -eq 0 ]]; then
    print_color $YELLOW "No devices found matching the specified prefix. Exiting."
    exit 0
fi

# Show devices to be processed
echo
print_color $BLUE "Devices to be $(if [[ "$DRY_RUN" == "true" ]]; then echo "analyzed"; else echo "deleted"; fi):"
echo "$filtered_devices" | jq -r '.[] | "  - " + .name + " (ID: " + .id + ")"'

# Show additional details
echo
print_color $BLUE "Device details:"
echo "$filtered_devices" | jq -r '.[] | "  Device: " + .name + "\n    ID: " + .id + "\n    Created: " + .created_at + "\n    Last seen: " + (.last_seen_at // "Never") + "\n    User: " + (.last_seen_user.email // "Unknown") + "\n"'

# Show warning for live mode but proceed automatically
if [[ "$DRY_RUN" == "false" ]]; then
    echo
    print_color $RED "⚠️  WARNING: This will permanently delete $filtered_count devices!"
    print_color $YELLOW "FORCE_DELETE is enabled - proceeding automatically without confirmation"
    sleep 2  # Brief pause to allow reading the warning
fi

# Process devices
print_color $BLUE "\\n${DRY_RUN:+DRY RUN: }Processing $filtered_count devices..."

if [[ "$DRY_RUN" == "true" ]]; then
    print_color $YELLOW "DRY RUN MODE - No devices will actually be deleted"
fi

deleted_count=0
failed_count=0

# Process each device
while IFS= read -r device_data; do
    device_id=$(echo "$device_data" | jq -r '.id')
    device_name=$(echo "$device_data" | jq -r '.name')
    
    echo "Processing: $device_name (ID: $device_id)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_color $YELLOW "  ○ Would delete: $device_name"
        ((deleted_count++))
    else
        # Actually delete the device
        delete_response=$(curl -s \
            -X DELETE \
            -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
            -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/devices/physical-devices/$device_id")
        
        # Check if deletion was successful
        if echo "$delete_response" | jq -e '.success' > /dev/null; then
            print_color $GREEN "  ✓ Deleted: $device_name"
            ((deleted_count++))
        else
            print_color $RED "  ✗ Failed to delete: $device_name"
            echo "$delete_response" | jq '.errors' | sed 's/^/    /'
            ((failed_count++))
        fi
    fi
    
    # Small delay to be respectful to the API
    sleep 0.5
    
done < <(echo "$filtered_devices" | jq -c '.[]')

# Print summary
echo
print_color $BLUE "=================================================="
print_color $BLUE "SUMMARY"
print_color $BLUE "=================================================="
echo "Total devices processed: $filtered_count"
if [[ "$DRY_RUN" == "true" ]]; then
    print_color $GREEN "Devices that would be deleted: $deleted_count"
else
    print_color $GREEN "Successfully deleted: $deleted_count"
    if [[ $failed_count -gt 0 ]]; then
        print_color $RED "Failed deletions: $failed_count"
    fi
fi
echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')"

# Set appropriate exit code
if [[ "$DRY_RUN" == "false" && $failed_count -gt 0 ]]; then
    print_color $RED "\\nScript completed with errors!"
    exit 1
else
    print_color $GREEN "\\nScript completed successfully!"
    exit 0
fi