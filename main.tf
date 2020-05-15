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

variable "address_space" { # subnet address range in CIDR notation
default = "192.168.41.0/24"
}

variable "compute_image" {
  default = "CentOS 7.7"
}

variable "compute_flavor" {
  default = "hotdog"
}

variable "floatingip_pool" {
  default = "internet"
}

# https://www.terraform.io/docs/providers/openstack/index.html
# uses clouds.yml
provider "openstack" {
  cloud = var.cloud
  version = "~> 1.25"
}

data "openstack_networking_network_v2" "internet" {
  name = var.floatingip_pool
}

resource "openstack_compute_keypair_v2" "terraform" {
  name       = "${var.instance_prefix}-keypair"
  public_key = file(var.ssh_key_file) # should be .pub one
}

resource "openstack_networking_network_v2" "net" {
  name = "${var.instance_prefix}-net"
  admin_state_up = "true"
}
resource "openstack_networking_subnet_v2" "net" {
  name = "${var.instance_prefix}-subnet"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.address_space
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  ip_version      = 4
}

resource "openstack_compute_instance_v2" "control" {
  name = "${var.instance_prefix}-control-0"
  image_name = var.compute_image
  flavor_name = var.compute_flavor
  key_pair = openstack_compute_keypair_v2.terraform.name
  network {
    uuid = openstack_networking_network_v2.net.id
  }
  depends_on = [openstack_networking_subnet_v2.net]
}

resource "openstack_networking_floatingip_v2" "fip" {
  pool = var.floatingip_pool
}
resource "openstack_compute_floatingip_associate_v2" "fip" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  instance_id = openstack_compute_instance_v2.control.id
}

resource "openstack_networking_router_v2" "external" {
  name                = "external"
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.internet.id
}

resource "openstack_networking_router_interface_v2" "net" {
  router_id = openstack_networking_router_v2.external.id
  subnet_id = openstack_networking_subnet_v2.net.id
}

output "proxy_ip_addr" {
  value = openstack_compute_floatingip_associate_v2.fip.floating_ip
}