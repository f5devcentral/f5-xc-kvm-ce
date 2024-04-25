terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
    }
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api-creds-p12
  url          = var.api-url
}

provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "kvm-ce-user_data" {
  template = file("${path.module}/../../terraform/cloudinit/user-data.tpl")
  vars     = {
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
  template = file("${path.module}/../../terraform/cloudinit/meta-data.tpl")
  vars     = {
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

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.kvm-ce-cloudinit.id

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "volterra_securemesh_site" "kvm-ce-secure-mesh-site" {
  name       = var.kvm-ce-site-name
  namespace  = "system"

  volterra_certified_hw = var.kvm-certified-hw
  master_node_configuration {
    name = var.kvm-ce-node-name
  }

  coordinates {
    latitude = var.kvm-ce-latitude
    longitude = var.kvm-ce-longitude
  }
}

resource "volterra_registration_approval" "kvm-ce-site-registration" {
  depends_on   = [ libvirt_domain.kvm-ce, volterra_securemesh_site.kvm-ce-secure-mesh-site ]

  cluster_name = var.kvm-ce-site-name
  hostname     = var.kvm-ce-node-name
  cluster_size = 1
  retry        = 5
  wait_time    = 120
}
