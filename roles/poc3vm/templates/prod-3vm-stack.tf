variable "node_count" {default = 3}

variable "instance_ip" {
  type = "map"
  default = {
    "0" = "200.201"
    "1" = "200.202"
    "2" = "200.203"
    "3" = "200.204"
    "4" = "200.205"
    "5" = "200.206"
    "6" = "200.207"
    "7" = "200.208"
    "8" = "200.209"
    "9" = "200.210"
    "10" = "200.211"
    "11" = "200.212"
    "12" = "200.213"
    "13" = "200.214"
    "14" = "200.215"
    "15" = "200.216"
    "16" = "200.217"
    "17" = "200.218"
    "18" = "200.219"
    "19" = "200.220"
  }
}

provider "vsphere" {
  user           = "root"
  password       = "TnPassw0rd1"
  vsphere_server = "10.9.19.204"

  allow_unverified_ssl = true
}

#resource "null_resource" "cls-ansible-hosts" {
#  triggers {
#    instance_count = "${var.node_count}"
#  }
#  provisioner "local-exec" {
#    command = "echo > /etc/ansible/hosts"
#  }
#}

data "vsphere_datacenter" "dc" {
  name = "technet-asia.com"
}

data "vsphere_datastore" "datastore" {
  name          = "local_datastore2"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "technet-cluster"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${data.vsphere_compute_cluster.cluster.name}/Resources/"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "PG_ICO_Infra_MGM"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "Terraform-RHEL6-Template"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "prod-vm-stack" {
  name   = "prod-vm-${format("%02d", count.index+1)}"
  num_cpus   = 2
  memory = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "prod-vm-${format("%02d", count.index+1)}"
        domain    = ""
      }

      network_interface {
        ipv4_address = "192.168.${lookup(var.instance_ip, count.index)}"
        ipv4_netmask = 24
      }

      ipv4_gateway = "192.168.200.254"
    }
  }

#  disk {
#    name = "newDisk"
#    datastore = "local_datastore2"
#    size = 2
#  }

#  provisioner "local-exec" {
#    command = "echo 192.168.100.${lookup(var.instance_ip, count.index)} ansible_ssh_user=root ansible_ssh_pass=P@ssw0rd >> /etc/ansible/hosts"
#  }
#
  count = "${var.node_count}"
}

#resource "null_resource" "run-ansible" {
#  triggers {
#    instance_count = "${var.node_count}"
#  }
#  depends_on = ["vsphere_virtual_machine.prod-vm-stack"]
#  provisioner "local-exec" {
#    command = "ansible-playbook /ansible/vm_playbook.yml"
#  }
#}

