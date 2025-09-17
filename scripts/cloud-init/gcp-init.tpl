#!/bin/bash

set -euxo pipefail

ROLE="${role}"

LOGFILE="/var/log/startup-script.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Startup script started at $(date)"

# Wait for network connectivity
until ping -c1 8.8.8.8 &>/dev/null; do
    echo "Waiting for network..."
    sleep 5
done

# Set timezone
timedatectl set-timezone Europe/Paris

# Update and install common packages
apt-get update -y
apt-get install -y wget traceroute unzip build-essential hping3 net-tools nmap curl gnupg2

if [[ "$ROLE" == "warp_connector" ]]; then
    echo "Configuring Warp Connector..."

    # Install WARP
    curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
    apt-get update -y
    apt-get install -y cloudflare-warp

    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ip-forward.conf

    # Ensure warp service is enabled and running
    systemctl enable warp-svc
    systemctl start warp-svc
    
    # Wait for service to be ready
    sleep 10
    
    # Check service status
    systemctl status warp-svc --no-pager
    
    # Register and connect
    warp-cli --accept-tos connector new ${warp_token}
    
    # Wait a moment after registration
    sleep 5
    
    # Connect
    warp-cli --accept-tos connect
    
    # Verify connection status
    sleep 10
    warp-cli --accept-tos status || echo "WARP status check failed, continuing..."
    
    # If still disconnected, try to connect again
    if ! warp-cli --accept-tos status | grep -q "Connected" 2>/dev/null; then
        echo "First connection attempt failed, trying again..."
        sleep 5
        warp-cli --accept-tos connect || echo "WARP connect retry failed, continuing..."
        sleep 10
        warp-cli --accept-tos status || echo "WARP final status check failed, continuing..."
    fi

elif [[ "$ROLE" == "cloudflared" ]]; then
    echo "Configuring Cloudflared tunnel..."

    # Install cloudflared
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared-linux-amd64.deb
    cloudflared service install ${tunnel_secret_gcp}
    systemctl restart cloudflared.service

    # Create /etc/ssh/ca_cloudflare.pub and paste the gateway_ca_certificate
    echo "${gateway_ca_certificate}" | tee /etc/ssh/ca_cloudflare.pub
    chmod 600 /etc/ssh/ca_cloudflare.pub

    # Allowing One-time PIN contractor to login
    adduser --force-badname oktauser2.bcey3
    echo "oktauser2.bcey3:bob" | chpasswd
    usermod -aG sudo oktauser2.bcey3

    # Modify /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i '/PubkeyAuthentication yes/a TrustedUserCAKeys \/etc\/ssh\/ca_cloudflare.pub' /etc/ssh/sshd_config
    
    # Add compatible KexAlgorithms to SSH config for better compatibility
    echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256" >> /etc/ssh/sshd_config
    
    # Restart SSH service to apply changes
    systemctl restart ssh

    # Create directory for Web Servers
    cd /home/
    mkdir webserver1
    mkdir webserver2

    # very basic webserver 1
    cd /home/webserver1/
    cat > /home/webserver1/index.html << 'EOF'
${intranet_html}
EOF
    python3 -m http.server ${intranet_app_port} &

    # very basic webserver 2
    cd /home/webserver2/
    cat > /home/webserver2/index.html << 'EOF'
${competition_html}
EOF
    python3 -m http.server ${competition_app_port} &

    # Wait for 60 seconds
    sleep 60

else
    echo "Default VM setup, no special role"

    # Configure SSH daemon for better compatibility
    echo "Configuring SSH daemon for compatibility..."

    # Add compatible KexAlgorithms to SSH config
    echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256" >> /etc/ssh/sshd_config
    
    # Restart SSH service to apply changes
    systemctl restart ssh
    
fi

# Install Datadog NPM monitoring
echo "Installing Datadog NPM for gcp with role ${role}"

# Install Datadog Agent
DD_API_KEY=${datadog_api_key} DD_SITE=${datadog_region} bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

# Wait for agent to be installed
sleep 10

# Create Datadog agent configuration
cat >> /etc/datadog-agent/datadog.yaml << 'EOF'
# Basic monitoring configuration for free tier
process:
  enabled: true

# Dynamic tags based on cloud and role
tags:
  - environment:zero-trust-demo
  - cloud:gcp
  - role:${role}
  - managed-by:terraform

# Logging configuration
log_level: info
log_file: /var/log/datadog/agent.log
EOF

# Create comprehensive monitoring configs
mkdir -p /etc/datadog-agent/conf.d

# Process monitoring for zero-trust components
cat > /etc/datadog-agent/conf.d/process.yaml << 'EOF'
init_config:

instances:
  - name: zero_trust_processes
    search_string:
      - cloudflared
      - warp-cli
      - warp-svc
      - python3
      - ssh
    exact_match: false
    collect_children: true
    user: root
EOF

# Custom metrics for zero-trust services (only for cloudflared role)
if [[ "$ROLE" == "cloudflared" ]]; then
cat > /etc/datadog-agent/conf.d/http_check.yaml << 'EOF'
init_config:

instances:
  - name: local_web_services
    url: http://localhost:${intranet_app_port}
    timeout: 5
    tags:
      - service:intranet_web_app
      - cloud:gcp
      - role:${role}
    
  - name: local_web_services_sensitive
    url: http://localhost:${competition_app_port}
    timeout: 5
    tags:
      - service:competition_web_app
      - cloud:gcp
      - role:${role}
EOF
fi

# System metrics enhancement
cat > /etc/datadog-agent/conf.d/system_core.yaml << 'EOF'
init_config:

instances:
  - collect_service_check: true
    tags:
      - environment:zero-trust-demo
      - cloud:gcp
      - role:${role}
EOF

# Directory monitoring for configuration files
cat > /etc/datadog-agent/conf.d/directory.yaml << 'EOF'
init_config:

instances:
  - directory: /etc/ssh
    name: ssh_config_monitoring
    pattern: "*.conf"
    tags:
      - config_type:ssh
      - cloud:gcp
      - role:${role}
      
  - directory: /etc/datadog-agent
    name: datadog_config_monitoring
    pattern: "*.yaml"
    tags:
      - config_type:datadog
      - cloud:gcp
      - role:${role}
EOF

# Basic agent permissions
chmod 755 /opt/datadog-agent/embedded/bin/system-probe 2>/dev/null || true

# Restart agent
echo "Restarting Datadog agent..."
systemctl restart datadog-agent

# Wait and check status
sleep 5
if systemctl is-active --quiet datadog-agent; then
    echo "Datadog agent is running successfully"
else
    echo "WARNING: Datadog agent may not be running properly"
    systemctl status datadog-agent --no-pager
fi

echo "Datadog monitoring installation completed for gcp - ${role}"

echo "Startup script completed at $(date)"