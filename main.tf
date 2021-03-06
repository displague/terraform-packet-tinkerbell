# Configure the Packet Provider.
provider "packet" {
  auth_token = var.packet_api_token
  version    = "~> 2.10.1"
}

# Create a new VLAN in datacenter "ewr1"
resource "packet_vlan" "provisioning-vlan" {
  description = "provisioning-vlan"
  facility    = var.facility
  project_id  = var.project_id
}

# Create a device and add it to tf_project_1
resource "packet_device" "tink-provisioner" {
  hostname         = "tink-provisioner"
  plan             = var.device_type
  facilities       = [var.facility]
  operating_system = var.provisioner_os
  billing_cycle    = "hourly"
  project_id       = var.project_id
  network_type     = "hybrid"

  provisioner "file" {
    source      = "assets/"
    destination = "/root/"
  }
}

# Create a device and add it to tf_project_1
resource "packet_device" "tink-worker" {
  count = var.workers

  hostname         = "tink-worker-${count.index}"
  plan             = var.device_type
  facilities       = [var.facility]
  operating_system = "custom_ipxe"
  ipxe_script_url  = "https://boot.netboot.xyz"
  always_pxe       = "true"
  billing_cycle    = "hourly"
  project_id       = var.project_id
  network_type     = "layer2-individual"
}

# Attach VLAN to provisioner
resource "packet_port_vlan_attachment" "provisioner" {
  device_id = packet_device.tink-provisioner.id
  port_name = "eth1"
  vlan_vnid = packet_vlan.provisioning-vlan.vxlan
}

# Attach VLAN to worker
resource "packet_port_vlan_attachment" "worker" {
  count     = var.workers
  device_id = packet_device.tink-worker[count.index].id
  port_name = "eth0"
  vlan_vnid = packet_vlan.provisioning-vlan.vxlan
}

output "provisioner_dns_name" {
  value = "${split("-", packet_device.tink-provisioner.id)[0]}.packethost.net"
}

output "provisioner_ip" {
  value = packet_device.tink-provisioner.network[0].address
}

output "worker_mac_addr" {
  // TODO(displague) get all of the mac addresses, for_each
  value = <<EOT
%{ for port in packet_device.tink-worker.*.ports ~}
${port[1].mac}
%{ endfor ~}
EOT
}
