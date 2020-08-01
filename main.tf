# Configure the Packet Provider.
provider "packet" {
  auth_token = var.packet_api_token
  version    = "~> 3.0.0"
}

# Create a new VLAN in datacenter "ewr1"
resource "packet_vlan" "vlan" {
  description = "provisioning-vlan"
  facility    = var.facility
  project_id  = var.project_id
}

# Create a device and add it to tf_project_1
resource "packet_device" "provisioner" {
  hostname         = "tink-provisioner"
  plan             = var.device_type
  facilities       = [var.facility]
  operating_system = var.provisioner_os
  billing_cycle    = "hourly"
  project_id       = var.project_id

  provisioner "file" {
    source      = "${path.module}/assets/"
    destination = "/root/"
    connection {
      host    = self.access_public_ipv4
      user    = "root"
      timeout = "300s"
    }
  }
}

# Create a device and add it to tf_project_1
resource "packet_device" "worker" {
  count = var.workers

  hostname         = "tink-worker-${count.index}"
  plan             = var.device_type
  facilities       = [var.facility]
  operating_system = "custom_ipxe"
  ipxe_script_url  = "https://boot.netboot.xyz"
  always_pxe       = "true"
  billing_cycle    = "hourly"
  project_id       = var.project_id
}

resource "packet_device_network_type" "provisioner" {
  device_id = packet_device.provisioner.id
  type      = "hybrid"

  provisioner "remote-exec" {
    connection {
      host    = packet_device.provisioner.access_public_ipv4
      user    = "root"
      timeout = "300s"
    }

    inline = [
      "chmod +x /root/setup.sh",
      "/root/setup.sh",
      "cd /root/deploy",
      "source ../envrc",
      "docker-compose up -d",
    ]
  }
}

resource "packet_device_network_type" "worker" {
  count = var.workers

  device_id = packet_device.worker[count.index].id
  type      = "layer2-individual"
}

# Attach VLAN to provisioner
resource "packet_port_vlan_attachment" "provisioner" {
  device_id = packet_device_network_type.provisioner.device_id
  port_name = "eth1"
  vlan_vnid = packet_vlan.vlan.vxlan
}

# Attach VLAN to worker
resource "packet_port_vlan_attachment" "worker" {
  count = var.workers

  device_id = packet_device_network_type.worker[count.index].id
  port_name = "eth0"
  vlan_vnid = packet_vlan.vlan.vxlan
}
