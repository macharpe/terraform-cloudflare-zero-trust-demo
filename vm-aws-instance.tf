#==========================================================
# Key Pairs for AWS Instances
#==========================================================
# AWS Key Pair for Service on AWS
resource "aws_key_pair" "aws_ec2_service_key_pair" {
  key_name   = "aws_ssh_service"
  public_key = module.ssh_keys.aws_ssh_service_public_key

  tags = {
    Name        = "SSH Key for SSH Service EC2"
    Environment = var.cf_aws_tag
  }
}

# AWS Key Pair for Cloudflared
resource "aws_key_pair" "aws_ec2_cloudflared_key_pair" {
  count      = var.aws_cloudflared_count
  key_name   = "aws_ssh_cloudflared_${count.index}"
  public_key = module.ssh_keys.aws_ssh_public_key[count.index]

  tags = {
    Name        = "SSH Key for Cloudflared EC2"
    Environment = var.cf_aws_tag
  }
}

# AWS Key Pair for VNC Service
resource "aws_key_pair" "aws_ec2_vnc_key_pair" {
  key_name   = "aws_ssh_vnc_service"
  public_key = module.ssh_keys.aws_vnc_service_public_key

  tags = {
    Name        = "SSH Key for VNC EC2"
    Environment = var.cf_aws_tag
  }
}



#==========================================================
# Custom VPC and Subnets Configuration
#==========================================================
resource "aws_vpc" "aws_custom_vpc" {

  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "My VPC for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

resource "aws_subnet" "aws_private_subnet" {
  vpc_id            = aws_vpc.aws_custom_vpc.id
  cidr_block        = var.aws_private_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "Private Subnet for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

resource "aws_subnet" "aws_public_subnet" {
  vpc_id                  = aws_vpc.aws_custom_vpc.id
  cidr_block              = var.aws_public_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Required for public subnet

  tags = {
    Name        = "Public Subnet for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}


#==========================================================
# Internet Access Infrastructure (NAT Gateway)
#==========================================================
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aws_custom_vpc.id

  tags = {
    Name        = "Internet Gateway for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "Elastic IP for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.aws_public_subnet.id # Requires public subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name        = "NAT Gateway for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aws_custom_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "Private Route Table for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

# Association between private subnet and route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.aws_private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}


#Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aws_custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "Public Route Table for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

# Association between public subnet and route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.aws_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}




#==========================================================
# Local Values for Instance Configuration
#==========================================================
locals {
  # Common instance configuration
  aws_common_instance_config = {
    ami           = var.aws_ec2_instance_config_ami_id
    instance_type = var.aws_ec2_instance_config_type
    subnet_id     = aws_subnet.aws_private_subnet.id
  }

  # Common user data template variables
  aws_common_user_data_vars = merge(local.global_monitoring, local.global_okta, local.global_security, {
    users                 = local.global_users.aws_users
    tunnel_secret_aws     = module.cloudflare.aws_extracted_token
    ca_cloudflare_browser = module.cloudflare.pubkey_short_lived_certificate
    path                  = path.module
  })

  # Common tags
  aws_common_tags = {
    Environment = var.cf_aws_tag
  }
}

#==========================================================
# EC2 Instances: Cloudflared EC2 Instances
#==========================================================
resource "aws_instance" "cloudflared_aws" {
  count                  = var.aws_cloudflared_count
  ami                    = local.aws_common_instance_config.ami
  instance_type          = local.aws_common_instance_config.instance_type
  subnet_id              = local.aws_common_instance_config.subnet_id
  vpc_security_group_ids = [aws_security_group.aws_cloudflared_sg.id]
  key_name               = aws_key_pair.aws_ec2_cloudflared_key_pair[count.index].key_name

  user_data = templatefile("${path.module}/scripts/cloud-init/aws-init.tftpl", merge(local.aws_common_user_data_vars, {
    role     = "cloudflared"
    hostname = "${var.aws_ec2_cloudflared_name}-${count.index}"
  }))

  tags = merge(local.aws_common_tags, {
    Name = "${var.aws_ec2_cloudflared_name}-${count.index}"
  })
}



#==========================================================
# EC2 Instances: SERVICE Browser SSH EC2 Instances
#==========================================================
resource "aws_instance" "aws_ec2_service_instance" {
  ami                    = local.aws_common_instance_config.ami
  instance_type          = local.aws_common_instance_config.instance_type
  subnet_id              = local.aws_common_instance_config.subnet_id
  vpc_security_group_ids = [aws_security_group.aws_ssh_server_sg.id]
  key_name               = aws_key_pair.aws_ec2_service_key_pair.key_name

  user_data = templatefile("${path.module}/scripts/cloud-init/aws-init.tftpl", merge(local.aws_common_user_data_vars, {
    role     = "browser_ssh"
    hostname = var.aws_ec2_browser_ssh_name
  }))

  tags = merge(local.aws_common_tags, {
    Name = var.aws_ec2_browser_ssh_name
  })
}


#==========================================================
# EC2 Instance: VNC Browser Service
#==========================================================
resource "aws_instance" "aws_ec2_vnc_instance" {
  ami                    = local.aws_common_instance_config.ami
  instance_type          = local.aws_common_instance_config.instance_type
  subnet_id              = local.aws_common_instance_config.subnet_id
  vpc_security_group_ids = [aws_security_group.aws_vnc_server_sg.id]
  key_name               = aws_key_pair.aws_ec2_vnc_key_pair.key_name

  user_data = templatefile("${path.module}/scripts/cloud-init/aws-init.tftpl", merge(local.aws_common_user_data_vars, {
    role     = "vnc"
    hostname = var.aws_ec2_browser_vnc_name
  }))

  tags = merge(local.aws_common_tags, {
    Name = var.aws_ec2_browser_vnc_name
  })
}


#==========================================================
# Security Groups
#==========================================================

### Security Group for Cloudflared EC2 Replicas ###
resource "aws_security_group" "aws_cloudflared_sg" {
  name        = "cloudflared-replicas-sg"
  description = "Security group for cloudflared tunnel replicas"
  vpc_id      = aws_vpc.aws_custom_vpc.id

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cf_warp_cgnat_cidr]
  }

  ingress {
    description = "Allow ICMP from everywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound connection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


### Security Group for Browser SSH EC2 ###
resource "aws_security_group" "aws_ssh_server_sg" {
  name        = "browser-ssh-sg"
  description = "Allow SSH only from tunnel replicas"
  vpc_id      = aws_vpc.aws_custom_vpc.id
  depends_on  = [aws_security_group.aws_cloudflared_sg]

  # Allow SSH ingress from my IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cf_warp_cgnat_cidr]
  }

  # Allow SSH ingress from my VM running cloudflared
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_cloudflared_sg.id]
  }

  # Allow ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

### Security Group for Browser VNC EC2 ###
resource "aws_security_group" "aws_vnc_server_sg" {
  name        = "browser-vnc-sg"
  description = "Security group for VNC browser service"
  vpc_id      = aws_vpc.aws_custom_vpc.id
  depends_on  = [aws_security_group.aws_cloudflared_sg]

  # Allow SSH ingress from WARP CGNAT range
  ingress {
    description = "Allow SSH from WARP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cf_warp_cgnat_cidr]
  }

  # Allow SSH ingress from cloudflared instances
  ingress {
    description     = "Allow SSH from cloudflared instances"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_cloudflared_sg.id]
  }

  # Allow VNC ingress from cloudflared instances
  ingress {
    description     = "Allow VNC from cloudflared instances"
    from_port       = 5901
    to_port         = 5901
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_cloudflared_sg.id]
  }

  # Allow ICMP (ping)
  ingress {
    description = "Allow ICMP from everywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "VNC Browser Security Group"
    Environment = var.cf_aws_tag
  }

  lifecycle {
    create_before_destroy = true
  }
}
