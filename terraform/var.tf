variable "kvm-ce-qcow2" {
    description = "KVM CE QCOW2 image source"
    default = "https://downloads.volterra.io/releases/rhel/9/x86_64/images/qemu/rhel-9.2024.6-20240216073447.qcow2"
}

variable "kvm-ce-memory" {
    description = "Memory allocated to KVM CE"
    default = "16384"
}

variable "kvm-ce-vcpu" {
    description = "Number of vCPUs allocated to KVM CE"
    default = "4"
}

variable "kvm-ce-site-name" {
    description = "KVM CE site/cluster name"
    default = "kvm-ce-1"
}

variable "kvm-ce-node-name" {
    description = "KVM CE node hostname"
    default = "master-0"
}

variable "kvm-ce-storage-pool" {
    description = "KVM CE storage pool name"
    default = "default"
}

variable "kvm-ce-latitude" {
    description = "KVM CE node latitude"
    default = "37.34"
}

variable "kvm-ce-longitude" {
    description = "KVM CE node longitude"
    default = "121.89"
}

variable "kvm-ce-certified-hw" {
  description = "KVM CE certified hardware"
  default = "kvm-voltmesh"
}

variable "site-registration-token" {
    description = "F5XC environment registration token"
}

variable "xc-environment-api-endpoint" {
    description = "F5XC environment Maurice API endpoint"
    default = "ves.volterra.io"
}
