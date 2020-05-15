terraform {
  required_version = ">= 0.12, < 0.13"
}

variable "cloud" {
  default = "openstack" # Openstack cloud name in clouds.yaml to use
}

variable "ssh_key_file" { # key to put on nodes - must exist
  default = "~/.ssh/id_rsa.pub"
}

variable "instance_prefix" { #  prefix for resources
  default = "example"
}

variable "compute_image" {
  default = "Memset - CentOS 7 (2019-04-02)"
}

variable "compute_flavor" {
  default = "MSOS004"
}

variable "network" {
  default = "ospstackac2-du-net1"
}

# https://www.terraform.io/docs/providers/openstack/index.html
# uses clouds.yml
provider "openstack" {
  cloud = var.cloud
  version = "~> 1.25"
}

resource "openstack_compute_keypair_v2" "terraform" {
  name       = "${var.instance_prefix}-keypair"
  public_key = file(var.ssh_key_file) # should be .pub one
}

resource "openstack_compute_instance_v2" "control" {
  name = "${var.instance_prefix}-control-0"
  image_name = var.compute_image
  flavor_name = var.compute_flavor
  key_pair = openstack_compute_keypair_v2.terraform.name
  network {
    name = var.network
  }
}

output "control_ip_addr" {
  value = openstack_compute_instance_v2.control.access_ip_v4
}