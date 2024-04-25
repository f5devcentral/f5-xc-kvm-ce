## Overview

The documentation describes simplified KVM CE deployment with cloudinit. It includes deployment procedure for Terraform dmacvicar/libvirt provider.

Installation of KVM environment is not a part of this documentation. Please use Linux distribution installation procedure (i.e. https://help.ubuntu.com/community/KVM/Installation).

## Terraform deployment

In terraform folder you will find example of KVM CE deployment using Terraform dmacvicar/libvirt provider. This provider allows spawning KVM CE VM including cloudinit attribute in libvirt_domain. For more details, please refer to libvirt provider documentation, https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs.

To use libvirt xml extension there is a need to install xsltproc package (i.e. sudo apt install xsltproc)


#### Clone kvm-ce repository to your server.

    % git clone https://github.com/f5devcentral/f5-xc-kvm-ce.git
    % cd kvm-ce/terraform/

---

#### Provide all necessary values for variables in vars.tf file.

| Variable name | Description |
|---|---|
| kvm-ce-memory | Amount of memory allocated to KVM CE, minimum 16 GB |
| kvm-ce-vcpu | Number of vCPUs allocated to KVM CE, minimum 4 vCPUs/logical cores |
| kvm-ce-storage-pool | KVM CE storage pool name. Please use `virsh pool-list` to select preferred storage pool |
| kvm-ce-site-name | KVM CE site/cluster name |
| kvm-ce-node-name | KVM CE node hostname |
| kvm-ce-latitude | KVM CE node latitude |
| kvm-ce-longitude | KVM CE node longitude |
| site-registration-token | F5XC environment site registration token |
| xc-environment-api-endpoint | F5XC environment API endpoint |

> Please be aware to not to store unsafely your registration site token.

---

#### If needed add another interface (eth1 - inside) in main.tf (kvm-ce libvirt_domain resource)

        network_interface {
            network_name = "default"
        }
         network_interface {
            network_name = "inside"
        }

Please configure F5XC Secure Mesh Site with interface assignment to Outside and Inside.


---

#### If needed increase file system partition

* download KVM CE qcow2 (https://downloads.volterra.io/releases/images/2021-03-01/centos-7.2009.5-202103011045.qcow2)
* run **qemu-img resize** command (i.e. `qemu-img resize centos-7.2009.5-202103011045.qcow2 100G)`
* update **kvm-ce-qcow2** variable in var.tf file to point to local qcow2 image

---

#### Performance recommendations

* use macvtap or passthrough network interfaces, i.e.

        network_interface {
            macvtap = "eno1.10"
        }

* use vCPU pinning technique to assing specific HV logical cores to KVM CE VM

    * prepare cpu-pinning.xsl file, i.e.

            <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
                <xsl:template match="@*|node()" name="identity">
                    <xsl:copy>
                        <xsl:apply-templates select="@*|node()" />
                    </xsl:copy>
                </xsl:template>
                <xsl:template match="domain/*[1]">
                <xsl:if test="not(cputune)">
                    <cputune>
                        <vcpupin vcpu="0" cpuset="1"/>
                        <vcpupin vcpu="1" cpuset="25"/>
                        <vcpupin vcpu="2" cpuset="2"/>
                        <vcpupin vcpu="3" cpuset="26"/>
                        <emulatorpin cpuset="0,24"/>
                    </cputune>
                </xsl:if>
                <xsl:call-template name="identity" />
                </xsl:template>
            </xsl:stylesheet>

    * add **xml** argument in **kvm-ce libvirt_domain** resource

            xml {
              xslt = file("${path.module}/cpu-pinning.xsl")
            }


* use other techniques to increase HV CPU performance if needed

---

#### Run terraform deployment command

    % terraform init
    % terraform apply

---

#### KVM CE with automatic Secure Mesh Site and Site registration  using `volterraedge/volterra` terraform provider

To extend KVM CE with automatic Secure Mesh Site and Site registration please update main.tf file adding `volterraedge/volterra` provider and new resources: **volterra_volterra_securemesh_site** and **volterra_registration_approval**.


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

    resource "volterra_volterra_securemesh_site" "kvm-ce-secure-mesh-site" {
      name       = var.kvm-ce-site-name
      namespace  = "system"

      volterra_certified_hw = "kvm-regular-nic-voltmesh"
      master_node_configuration {
        name = var.kvm-ce-host-name
      }

      latitude = var.kvm-ce-latitude
      longitude = var.kvm-ce-longitude
    }

    resource "volterra_registration_approval" "kvm-ce-site-registration" {
      depends_on   = [ libvirt_domain.kvm-ce ]

      cluster_name = var.kvm-ce-site-name
      hostname     = var.kvm-ce-node-name
      cluster_size = 1
      retry        = 5
      wait_time    = 60
    }

## Support

For support, please open a GitHub issue.  Note, the code in this repository is community supported and is not supported by F5 Networks.  For a complete list of supported projects please reference [SUPPORT.md](SUPPORT.md).

## Community Code of Conduct

Please refer to the [F5 DevCentral Community Code of Conduct](code_of_conduct.md).

## License

[Apache License 2.0](LICENSE)

## Copyright

Copyright 2014-2020 F5 Networks Inc.

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects.
Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein.
You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.
