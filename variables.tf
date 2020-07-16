variable "packet_api_token" {
  description = "Packet user api token"
}

variable "project_id" {
  description = "Project ID"
}

variable "provisioner_os" {
  description = "Provisioner Operating System"
  default     = "ubuntu_20_04"
}

variable "facility" {
  description = "Packet facility to provision in"
  default     = "sjc1"
}

variable "device_type" {
  description = "Type of device to provision"
  default     = "c2.medium.x86"
}

variable "workers" {
  description = "Number of workers to provision"
  default     = "1"
}