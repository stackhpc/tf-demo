terraform {
  required_version = ">= 0.12, < 0.13"
}

# https://www.terraform.io/docs/providers/openstack/index.html
# uses clouds.yml
provider "openstack" {
  cloud = local.config.cloud
  version = "~> 1.25"
}
provider "local" {
  version = "~> 1.4"
}
provider "template" {
  version = "~> 2.1"
}

data "external" "tf_control_hostname" {
  program = ["./gethost.sh"] 
}

locals {
  config = yamldecode(file("group_vars/all.yml"))
  tf_dir = "${data.external.tf_control_hostname.result.hostname}:${path.cwd}"
}

resource "openstack_compute_keypair_v2" "terraform" {
  name       = "${local.config.instance_prefix}-keypair"
  public_key = file("${local.config.ssh_key_file}") # should be .pub one
}

resource "openstack_compute_instance_v2" "control" {
  name = "${local.config.instance_prefix}-control-0"
  image_name = local.config.control_image
  flavor_name = local.config.control_flavor
  key_pair = openstack_compute_keypair_v2.terraform.name
  network {
    name = local.config.network
  }
  metadata = {
    "terraform directory" = local.tf_dir
  }
}

resource "openstack_compute_instance_v2" "compute" {
  count = local.config.num_compute

  name = "${local.config.instance_prefix}-compute-${count.index}"
  image_name = local.config.compute_image
  flavor_name = local.config.compute_flavor
  key_pair = openstack_compute_keypair_v2.terraform.name
  network {
    name = local.config.network
  }
  metadata = {
    "terraform directory" = local.tf_dir
  }
}

data "template_file" "inventory" {
  template = "${file("${path.module}/inventory.tpl")}"
  vars = {
      ssh_user_name = local.config.ssh_user_name
      proxy_ip = openstack_compute_instance_v2.control.network[0].fixed_ip_v4
      control = <<EOT
${openstack_compute_instance_v2.control.name} ansible_host=${openstack_compute_instance_v2.control.network[0].fixed_ip_v4}
EOT
      computes = <<EOT
%{ for compute in openstack_compute_instance_v2.compute}${compute.name} ansible_host=${compute.network[0].fixed_ip_v4}
%{ endfor }
EOT
      instance_prefix = local.config.instance_prefix
      partition_name = local.config.partition_name
  }
  depends_on = [openstack_compute_instance_v2.control, openstack_compute_instance_v2.compute]
}

resource "local_file" "hosts" {
  content  = data.template_file.inventory.rendered
  filename = "${path.cwd}/inventory"
}

output "control_ip_addr" {
  value = openstack_compute_instance_v2.control.network[0].fixed_ip_v4
}