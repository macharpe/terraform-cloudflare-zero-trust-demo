#!/bin/bash

set -euxo pipefail

LOGFILE="/var/log/startup-script.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Cloudflared startup script started at $(date)"

sudo apt-get update -y && sudo apt-get install -y wget traceroute unzip build-essential hping3 net-tools nmap > /tmp/tools_install.log 2>&1
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
sudo cloudflared service install ${tunnel_secret_gcp}
systemctl restart cloudflared.service

# Create /etc/ssh/ca_cloudflare.pub and paste the gateway_ca_certificate
echo "${gateway_ca_certificate}" | sudo tee /etc/ssh/ca_cloudflare.pub

sudo chmod 600 /etc/ssh/ca_cloudflare.pub

# Allowing One-time PIN contractor to login
sudo adduser --force-badname oktauser2.bcey3
echo "oktauser2.bcey3:bob" | sudo chpasswd
sudo usermod -aG sudo oktauser2.bcey3

# Modify /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i '/PubkeyAuthentication yes/a TrustedUserCAKeys \/etc\/ssh\/ca_cloudflare.pub' /etc/ssh/sshd_config

# Create directory for Web Servers
cd /home/
sudo mkdir webserver1
sudo mkdir webserver2

# very basic webserver 1
cd /home/webserver1/
echo '<html><body><h1>Hello from GCP! This is my Administration Application</h1></body></html>' > /home/webserver1/index.html
sudo python3 -m http.server ${admin_web_app_port} &

# very basic webserver 2
cd /home/webserver2/
echo '<html><body><h1>Hello from GCP! This the Sensitive Competition App</h1></body></html>' > /home/webserver2/index.html
sudo python3 -m http.server ${sensitive_web_app_port} &

# Restart SSH service
sudo service ssh restart

# Set correct TimeZone
sudo timedatectl set-timezone Europe/Paris

# Wait for 60 seconds
sleep 60

# Datadog Agent installation
DD_API_KEY=${datadog_api_key} DD_SITE=${datadog_region} bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)" > /tmp/dd_install.log 2>&1

echo "Startup script completed at $(date)"
