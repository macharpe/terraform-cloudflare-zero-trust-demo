#==========================================================
# Load Balancing Demo - AWS EC2 Instance (DC1)
# VM Name: cloudflare-lb-demo-dc1-aws
#==========================================================
# This file creates an AWS EC2 instance for the Load Balancing demo.
# The VM runs nginx serving the Swiss Insurance website and is
# connected to Cloudflare via a cloudflared tunnel.
#
# To remove: Delete this file and run terraform apply
#==========================================================

#==========================================================
# Key Pair for LB AWS Instance
#==========================================================
resource "aws_key_pair" "aws_lb_key_pair" {
  count      = var.lb_demo_enabled ? 1 : 0
  key_name   = "aws_ssh_lb_demo"
  public_key = module.ssh_keys.aws_lb_demo_public_key

  tags = {
    Name        = "SSH Key for LB Demo EC2"
    Environment = var.cf_aws_tag
  }
}

#==========================================================
# Security Group for LB Demo Instance
#==========================================================
resource "aws_security_group" "aws_sg_lb_demo" {
  count       = var.lb_demo_enabled ? 1 : 0
  name        = "lb-demo-sg"
  description = "Security group for Load Balancing demo instance"
  vpc_id      = aws_vpc.aws_vpc_main.id

  # Allow SSH from WARP CGNAT range (for troubleshooting)
  ingress {
    description = "Allow SSH from WARP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cf_warp_cgnat_cidr]
  }

  # Allow HTTP from cloudflared instances (internal traffic)
  ingress {
    description     = "Allow HTTP from cloudflared instances"
    from_port       = var.lb_web_port
    to_port         = var.lb_web_port
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_sg_cloudflared.id]
  }

  # Allow HTTP from localhost (for cloudflared on same instance)
  ingress {
    description = "Allow HTTP from VPC (cloudflared tunnel)"
    from_port   = var.lb_web_port
    to_port     = var.lb_web_port
    protocol    = "tcp"
    cidr_blocks = [var.aws_private_cidr]
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

  tags = merge(local.aws_common_tags, {
    Name = "LB Demo Security Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#==========================================================
# EC2 Instance: Load Balancing Demo - DC1
#==========================================================
resource "aws_instance" "aws_vm_lb_demo" {
  count                  = var.lb_demo_enabled ? 1 : 0
  ami                    = local.aws_common_instance_config.ami
  instance_type          = local.aws_common_instance_config.instance_type
  subnet_id              = local.aws_common_instance_config.subnet_id
  vpc_security_group_ids = [aws_security_group.aws_sg_lb_demo[0].id]
  key_name               = aws_key_pair.aws_lb_key_pair[0].key_name

  dynamic "instance_market_options" {
    for_each = local.aws_spot_instance_options != null ? [1] : []
    content {
      market_type = local.aws_spot_instance_options.market_type
      spot_options {
        spot_instance_type             = local.aws_spot_instance_options.spot_options.spot_instance_type
        instance_interruption_behavior = local.aws_spot_instance_options.spot_options.instance_interruption_behavior
      }
    }
  }

  timeouts {
    create = local.final_aws_timeouts.vm.create
    update = local.final_aws_timeouts.vm.update
    delete = local.final_aws_timeouts.vm.delete
  }

  user_data = templatefile("${path.module}/scripts/cloud-init/aws-lb-init.tftpl", {
    hostname             = var.lb_aws_vm_name
    lb_web_port          = var.lb_web_port
    tunnel_token         = module.cloudflare.lb_aws_tunnel_token
    swiss_insurance_html = file("${path.module}/scripts/html/swiss-insurance.html")
    datadog_api_key      = var.datadog_api_key
    datadog_region       = var.datadog_region
  })

  tags = merge(local.aws_common_tags, {
    Name = var.lb_aws_vm_name
  })
}
