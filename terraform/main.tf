terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "kvm-ce-user_data" {
  template = file("${path.module}/cloudinit/user-data.tpl")
  vars = {
    "site-registration-token"             = var.site-registration-token
    "xc-environment-api-endpoint"         = var.xc-environment-api-endpoint
    "cluster-name"                        = var.kvm-ce-site-name
    "host-name"                           = var.kvm-ce-node-name  
    "latitude"                            = var.kvm-ce-latitude
    "longitude"                           = var.kvm-ce-longitude
    "certified-hw"                        = var.kvm-ce-certified-hw
  }
}

data "template_file" "kvm-ce-meta_data" {
  template = file("${path.module}/cloudinit/meta-data.tpl")
  vars = {
    "host-name" = var.kvm-ce-node-name
  }
}

resource "libvirt_volume" "kvm-ce-volume" {
  name   = "${var.kvm-ce-site-name}-${var.kvm-ce-node-name}.qcow2"
  pool   = var.kvm-ce-storage-pool
  source = var.kvm-ce-qcow2
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "kvm-ce-cloudinit" {
  name      = "${var.kvm-ce-site-name}-${var.kvm-ce-node-name}-cloud-init.iso"
  pool      = var.kvm-ce-storage-pool
  user_data = data.template_file.kvm-ce-user_data.rendered
  meta_data = data.template_file.kvm-ce-meta_data.rendered
}

resource "libvirt_domain" "kvm-ce" {
  name   = "${var.kvm-ce-site-name}-${var.kvm-ce-node-name}"
  memory = var.kvm-ce-memory
  vcpu   = var.kvm-ce-vcpu

  disk {
    volume_id = libvirt_volume.kvm-ce-volume.id
  }

  cloudinit = libvirt_cloudinit_disk.kvm-ce-cloudinit.id

  cpu {
    mode = "host-passthrough"
  }
 
  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
