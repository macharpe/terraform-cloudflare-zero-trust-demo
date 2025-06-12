#!/usr/bin/env python3
"""
Known hosts cleanup script - Terraform compatible version
Place this file at: scripts/known_hosts_cleanup.py
"""

import os
import sys
import shutil
import json
from datetime import datetime
from pathlib import Path

def clean_known_hosts():
    """Remove everything below the marker line in known_hosts file"""
    
    # Use environment variable or default path
    known_hosts_file = os.environ.get('KNOWN_HOSTS_FILE', 
                                     os.path.expanduser("~/.ssh/known_hosts"))
    marker_line = "#################### BELOW IS SAFE TO DELETE #########################"
    
    result = {
        "success": False,
        "message": "",
        "backup_file": "",
        "lines_kept": 0
    }
    
    try:
        # Check if file exists
        if not os.path.exists(known_hosts_file):
            result["message"] = f"Error: {known_hosts_file} not found!"
            print(json.dumps(result), file=sys.stderr)
            sys.exit(1)
        
        # Create backup
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"{known_hosts_file}.backup.{timestamp}"
        shutil.copy2(known_hosts_file, backup_file)
        result["backup_file"] = backup_file
        
        # Read the file and find the marker
        with open(known_hosts_file, 'r') as f:
            lines = f.readlines()
        
        marker_index = None
        for i, line in enumerate(lines):
            if marker_line in line:
                marker_index = i
                break
        
        if marker_index is None:
            result["message"] = f"Marker line not found in {known_hosts_file}. No changes made - file left untouched."
            result["success"] = True  # Not an error, just nothing to do
            result["lines_kept"] = len(lines)  # All original lines preserved
            print(json.dumps(result))
            return True
        
        # Keep everything up to and including the marker line
        lines_to_keep = lines[:marker_index + 1]
        
        # Write the cleaned file
        with open(known_hosts_file, 'w') as f:
            f.writelines(lines_to_keep)
        
        result["success"] = True
        result["lines_kept"] = len(lines_to_keep)
        result["message"] = f"Successfully cleaned {known_hosts_file}"
        
        # Output for Terraform (JSON format for external data source)
        print(json.dumps(result))
        
        return True
        
    except Exception as e:
        result["message"] = f"Error: {str(e)}"
        print(json.dumps(result), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    clean_known_hosts()