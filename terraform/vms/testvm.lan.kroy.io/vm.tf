# variables that can be overriden
variable "hostname" { default = "testvm" }
variable "domain" { default = "lan.kroy.io" }
variable "memoryGB" { default = 2 }
variable "cpu" { default = 2 }
variable "network" { default = "vibr20" }
variable "disksize" { default = 20 }



resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  pool   = "VM"
  base_volume_id = libvirt_volume.os_tmpl.id
  size = var.disksize * 1024 * 1024 * 1024
}

# Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.hostname}-commoninit.iso"
  pool = "VM"
  user_data = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}


data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = var.hostname
    fqdn = "${var.hostname}.${var.domain}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}


# Create the machine
resource "libvirt_domain" "domain-vm" {
  qemu_agent = true
  name = "${var.hostname}.${var.domain}"
  memory = var.memoryGB * 1024
  vcpu = var.cpu
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
       volume_id = libvirt_volume.os_image.id
  }
  network_interface {
       wait_for_lease = true
       bridge = var.network
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
  provisioner "local-exec" {
    environment = {
        IP = join("",slice([for ip in flatten(libvirt_domain.domain-vm.*.network_interface.0.addresses) : ip if substr(ip,0,8) == "10.20.20"],0,1))
    }
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i $IP, --key-file=~/Documents/infra/terraform/keys/id_ansible -u root ~/Documents/infra/terraform/ansible/docker/deploy-docker_ubuntu.yml"

  }

}


resource "mikrotik_dhcp_lease" "dhcp" {
  address = join("",slice([for ip in flatten(libvirt_domain.domain-vm.*.network_interface.0.addresses) : ip if substr(ip,0,8) == "10.20.20"],0,1))
  macaddress = upper(join("",libvirt_domain.domain-vm.*.network_interface.0.mac))
  comment = "${var.hostname}.${var.domain}"
  hostname = var.hostname
}

