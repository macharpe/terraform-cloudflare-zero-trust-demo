#=========================================================================
#         SUBNET CALCULATION FOR WARP ROUTING Azure VMs
#=========================================================================

resource "null_resource" "python_script_azure_infrastructure" {
  provisioner "local-exec" {
    command = "python3 ${path.root}/modules/warp-routing/scripts/generate_subnets.py ${var.azure_subnet_cidr} azure"
  }

  triggers = {
    script_hash = filesha256("${path.module}/scripts/generate_subnets.py")
    input_cidr  = var.azure_subnet_cidr
  }
}

data "local_file" "azure_subnet_output" {
  filename = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_azure_internal_subnet.json"

  depends_on = [null_resource.python_script_azure_infrastructure]
}



#=========================================================================
#         SUBNET CALCULATION FOR WARP ROUTING GCP VMs
#=========================================================================

resource "null_resource" "python_script_gcp_infrastructure_warp" {
  provisioner "local-exec" {
    command = "python3 ${path.root}/modules/warp-routing/scripts/generate_subnets.py ${var.gcp_infra_cidr} ${var.gcp_warp_cidr} ${var.gcp_windows_rdp_cidr} gcp"
  }

  triggers = {
    script_hash = filesha256("${path.module}/scripts/generate_subnets.py")
    input_cidr  = var.gcp_infra_cidr
  }
}

data "local_file" "gcp_subnet_output" {
  filename = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_gcp_internal_subnet.json"

  depends_on = [null_resource.python_script_gcp_infrastructure_warp]
}



#=========================================================================
#         SUBNET CALCULATION FOR WARP ROUTING AWS VMs
#=========================================================================

resource "null_resource" "python_script_aws_infrastructure" {
  provisioner "local-exec" {
    command = "python3 ${path.root}/modules/warp-routing/scripts/generate_subnets.py ${var.aws_private_cidr} aws"
  }

  triggers = {
    script_hash = filesha256("${path.module}/scripts/generate_subnets.py")
    input_cidr  = var.aws_private_cidr
  }
}

data "local_file" "aws_subnet_output" {
  filename = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_aws_internal_subnet.json"

  depends_on = [null_resource.python_script_aws_infrastructure]
}
