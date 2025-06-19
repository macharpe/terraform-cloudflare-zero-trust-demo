import ipaddress
import sys
import json
import os
from datetime import datetime, timezone

def get_script_paths(provider):
    """Return absolute paths for reliable file operations"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, '..', 'output')
    os.makedirs(output_dir, exist_ok=True)
    return {
        'output': os.path.join(output_dir, f'warp_subnets_including_all_except_{provider}_internal_subnet.json'),
        'error': os.path.join(output_dir, f'{provider}_subnet_error.json')
    }

def validate_input(input_str):
    """Validate and normalize input with comprehensive checks"""
    # Only add /32 if there's no slash already present
    if '/' not in input_str:
        input_str += '/32'
    
    if input_str.count('/') != 1:
        raise ValueError(f"Invalid CIDR format: '{input_str}'")
    
    ip_part, mask_part = input_str.split('/')
    
    try:
        mask = int(mask_part)
        if not 0 <= mask <= 32:
            raise ValueError("Mask must be 0-32")
    except ValueError:
        raise ValueError(f"Invalid mask value: '{mask_part}'")
    
    try:
        network = ipaddress.ip_network(input_str, strict=True)
    except ValueError as e:
        raise ValueError(f"Invalid network: {str(e)}")
    
    return network

def infer_base_cidr(exclude_networks):
    """Infer common base CIDR from RFC1918 ranges for all exclude networks"""
    rfc1918_ranges = [
        ipaddress.ip_network("10.0.0.0/8"),
        ipaddress.ip_network("172.16.0.0/12"),
        ipaddress.ip_network("192.168.0.0/16"),
    ]

    # Check all exclude networks are in the same RFC1918 base network
    base_cidr = None
    for base in rfc1918_ranges:
        if all(net.subnet_of(base) for net in exclude_networks):
            base_cidr = base
            break

    if base_cidr is None:
        raise ValueError("All input subnets must be within the same RFC1918 private range")

    return base_cidr

def exclude_subnet_from_list(networks, exclude_net):
    """Exclude exclude_net from a list of networks, returning new list"""
    result = []
    for net in networks:
        if exclude_net.subnet_of(net):
            # Exclude from this net
            excluded_parts = list(net.address_exclude(exclude_net))
            result.extend(excluded_parts)
        else:
            # No overlap, keep as is
            result.append(net)
    return result

def calculate_exclusions(base_cidr, exclude_networks):
    """Exclude multiple subnets from base network"""
    remaining_networks = [base_cidr]

    for exclude_net in exclude_networks:
        remaining_networks = exclude_subnet_from_list(remaining_networks, exclude_net)

    return remaining_networks

def main():
    if len(sys.argv) < 3:
        error = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "error": "Invalid arguments",
            "usage": "python3 script.py <IP_or_CIDR_1> [<IP_or_CIDR_2> ...] <provider>",
            "example": "python3 script.py 10.156.70.0/24 10.156.82.0/24 gcp",
            "valid_providers": ["aws", "azure", "gcp"]
        }
        # Write to generic error file
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_dir = os.path.join(script_dir, '..', 'output')
        os.makedirs(output_dir, exist_ok=True)
        error_path = os.path.join(output_dir, 'subnet_error.json')
        with open(error_path, 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

    *input_strs, provider = sys.argv[1:]
    provider = provider.lower()

    valid_providers = ['aws', 'azure', 'gcp']
    if provider not in valid_providers:
        error = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "inputs_received": input_strs,
            "error_type": "InvalidProviderError",
            "message": f"Provider '{provider}' is not valid. Must be one of {valid_providers}.",
            "usage": "python3 script.py <IP_or_CIDR_1> [<IP_or_CIDR_2> ...] <provider>",
            "example": "python3 script.py 10.156.70.0/24 10.156.82.0/24 gcp"
        }
        paths = get_script_paths(provider)
        with open(paths['error'], 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

    paths = get_script_paths(provider)
    result = {}

    try:
        # Validate and process all inputs
        exclude_networks = [validate_input(s) for s in input_strs]
        base_cidr = infer_base_cidr(exclude_networks)
        
        # Calculate exclusions
        excluded_nets = calculate_exclusions(base_cidr, exclude_networks)
        
        # Build result structure
        result = {
            "metadata": {
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "script_version": "1.3",
                "inputs_received": input_strs,
                "base_network": str(base_cidr),
                "provider": provider
            },
            "exclusions": [
                {
                    "address": str(cidr),
                    "description": f"{provider.upper()} Excluded Subnet {i+1}",
                    "type": "calculated"
                } for i, cidr in enumerate(excluded_nets)
            ],
            "validation": {
                "rfc1918_compliant": True,
                "complete_coverage": len(excluded_nets) > 0
            }
        }

        with open(paths['output'], 'w') as f:
            json.dump(result, f, indent=2)
        
        print(f"Successfully generated {len(excluded_nets)} exclusion rules in {paths['output']}")

    except Exception as e:
        error = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "inputs_received": input_strs,
            "error_type": type(e).__name__,
            "message": str(e),
            "possible_fixes": [
                "Ensure all inputs are valid IPv4 addresses/CIDRs",
                "Check if all IPs belong to the same RFC1918 private range",
                "Verify network mask validity (0-32)",
                "Use a valid provider argument: aws, azure, or gcp"
            ]
        }
        with open(paths['error'], 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

if __name__ == "__main__":
    main()