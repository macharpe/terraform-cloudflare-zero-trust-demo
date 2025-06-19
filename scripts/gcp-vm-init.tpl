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
    warp-cli status
    
    # If still disconnected, try to connect again
    if ! warp-cli status | grep -q "Connected"; then
        echo "First connection attempt failed, trying again..."
        sleep 5
        warp-cli connect
        sleep 10
        warp-cli status
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

    # Create directory for Web Servers
    cd /home/
    mkdir webserver1
    mkdir webserver2

    # very basic webserver 1
    cd /home/webserver1/
    echo '<html><body><h1>Hello from GCP! This is my Administration Application</h1></body></html>' > /home/webserver1/index.html
    python3 -m http.server ${admin_web_app_port} &

    # very basic webserver 2
    cd /home/webserver2/
    echo '<html><body><h1>Hello from GCP! This the Sensitive Competition App</h1></body></html>' > /home/webserver2/index.html
    python3 -m http.server ${sensitive_web_app_port} &

    # Restart SSH service
    service ssh restart

    # Wait for 60 seconds
    sleep 60

else
    echo "Default VM setup, no special role"
fi

# Datadog Agent installation
DD_API_KEY=${datadog_api_key} DD_SITE=${datadog_region} bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

echo "Startup script completed at $(date)"