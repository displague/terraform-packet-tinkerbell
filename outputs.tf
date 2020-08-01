output "provisioner_dns_name" {
  value = "${split("-", packet_device.provisioner.id)[0]}.packethost.net"
}

output "provisioner_ip" {
  value = packet_device.provisioner.access_public_ipv4
}

output "worker_mac_addr" {
  // TODO(displague) get all of the mac addresses, for_each
  value = <<EOT
%{for port in packet_device.worker.*.ports~}
${port[1].mac}
%{endfor~}
EOT
}
