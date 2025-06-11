#==========================================================
# Key Pairs for AWS Instances
#==========================================================
# AWS Key Pair for Service on AWS
resource "aws_key_pair" "aws_ec2_service_key_pair" {
  key_name   = "aws_ssh_service"
  public_key = module.ssh_keys.aws_ssh_service_public_key

  tags = {
    Name        = "SSH Key for Service EC2"
    Environment = var.cf_aws_tag
  }
}

# AWS Key Pair for Cloudflared
resource "aws_key_pair" "aws_ec2_cloudflared_key_pair" {
  count      = var.aws_ec2_cloudflared_replica_count
  key_name   = "aws_ssh_cloudflared_${count.index}"
  public_key = module.ssh_keys.aws_ssh_public_key[count.index]

  tags = {
    Name        = "SSH Key for Cloudflared EC2"
    Environment = var.cf_aws_tag
  }
}



#==========================================================
# SSM Parameter Store for API Keys
#==========================================================
# Store the tunnel secret in SSM Parameter Store
resource "aws_ssm_parameter" "aws_cloudflare_tunnel_secret" {
  name  = "/myapp/cloudflare/aws-tunnel-secret"
  type  = "SecureString"
  value = module.cloudflare.aws_extracted_token

  tags = {
    Name        = "Cloudflare Tunnel Secret for AWS"
    Environment = var.cf_aws_tag
  }
}

# Store the Datadog API key in SSM Parameter Store
resource "aws_ssm_parameter" "datadog_api_key" {
  name  = "/myapp/datadog/datadog-api-key"
  type  = "SecureString"
  value = var.datadog_api_key

  tags = {
    Name        = "Datadog API Key"
    Environment = var.cf_aws_tag
  }
}



#==========================================================
# IAM Role for EC2 Instances to access SSM Parameter Store
#==========================================================
# IAM role for EC2 instances to access SSM parameters
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EC2 SSM Access Role"
    Environment = var.cf_aws_tag
  }
}

# IAM policy for accessing SSM parameters
resource "aws_iam_role_policy" "ec2_ssm_policy" {
  name = "ec2-ssm-parameter-policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/myapp/*"
        ]
      }
    ]
  })
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
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
  cidr_block        = var.aws_private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "Private Subnet for zero-trust demo"
    Environment = var.cf_aws_tag
  }
}

resource "aws_subnet" "aws_public_subnet" {
  vpc_id                  = aws_vpc.aws_custom_vpc.id
  cidr_block              = var.aws_public_subnet_cidr
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
# EC2 Instances: Cloudflared EC2 Instances
#==========================================================
resource "aws_instance" "cloudflared_aws" {
  count         = var.aws_ec2_cloudflared_replica_count
  ami           = var.aws_ec2_instance_config_ami_id
  instance_type = var.aws_ec2_instance_config_type

  subnet_id = aws_subnet.aws_private_subnet.id

  # Troubleshoot (remove after)
  # subnet_id                   = aws_subnet.aws_public_subnet.id
  # associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.aws_cloudflared_sg.id]

  key_name = aws_key_pair.aws_ec2_cloudflared_key_pair[count.index].key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/scripts/aws-cloudflared-init.yaml", {
    hostname          = "${var.aws_ec2_cloudflared_name}-${count.index}"
    tunnel_secret_aws = module.cloudflare.aws_extracted_token
    datadog_api_key   = var.datadog_api_key
    # aws_region     = var.aws_region
    datadog_region = var.datadog_region
  })

  tags = {
    Name        = "${var.aws_ec2_cloudflared_name}-${count.index}"
    Environment = var.cf_aws_tag
  }
}



#==========================================================
# EC2 Instances: SERVICE EC2 Instances
#==========================================================
resource "aws_instance" "aws_ec2_service_instance" {
  #  count         = 1
  ami           = var.aws_ec2_instance_config_ami_id
  instance_type = var.aws_ec2_instance_config_type

  subnet_id = aws_subnet.aws_private_subnet.id

  # Troubleshoot (remove after)
  # subnet_id                   = aws_subnet.aws_public_subnet.id
  # associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.aws_ssh_server_sg.id]

  key_name = aws_key_pair.aws_ec2_service_key_pair.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/scripts/aws-service-init.tftpl", {
    hostname              = "${var.aws_ec2_instsance_name}"
    ca_cloudflare_browser = module.cloudflare.pubkey_short_lived_certificate
    users                 = var.aws_users
    datadog_api_key       = var.datadog_api_key
    # aws_region     = var.aws_region
    datadog_region = var.datadog_region
    # Linux user for contractor
    okta_contractor_username = split("@", var.okta_bob_user_login)[0]
    okta_contractor_password = var.okta_bob_user_linux_password
  })

  tags = {
    Name        = "${var.aws_ec2_instsance_name}"
    Environment = var.cf_aws_tag
  }
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


### Security Group for Service EC2 ###
resource "aws_security_group" "aws_ssh_server_sg" {
  name        = "ssh-server-sg"
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

  # Allow VNC ingress from my VM running cloudflared
  ingress {
    from_port       = 5901
    to_port         = 5901
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
