terraform {
    required_version = ">= 0.13"
    required_providers {
        libvirt = {
            source  = "dmacvicar/libvirt"
            version = "0.6.2"
        }
        mikrotik = {
          source = "ddelnano/mikrotik"
          version = "0.3.6"
        }
    }
}

# instance the provider

provider "libvirt" {
    uri = "qemu+ssh://root@jack.lan.kroy.io/system"
}

provider "mikrotik" {
    host = "crs354.lan.kroy.io:8728"
    username = "admin"
    password = ""
}

resource "libvirt_volume" "os_tmpl" {
  name = "focal_os_tmpl"
  pool = "VM"
  source = "file:///home/kroy/Documents/infra/terraform/libvirt/diskimages/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}


