provider "linode" {
  key = "${var.linode_key}"
}

resource "linode_linode" "terraform-resource" {
  image = "Ubuntu 16.04 LTS"
  kernel = "Grub 2"
  name = "linode-example"
  group = "terraform-group"
  region = "Atlanta, GA, USA"
  size = 1024
  ssh_key = "${var.ssh_key}"
  root_password = "${var.root_password}"
}
