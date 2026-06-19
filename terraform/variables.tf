variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_default_zone" {
  description = "Default Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_default_zone_b" {
  description = "Second availability zone"
  type        = string
  default     = "ru-central1-b"
}

variable "yc_service_account_key_file" {
  description = "Path to Yandex Cloud service account key JSON"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
}

variable "image_id" {
  description = "Ubuntu image ID in Yandex Cloud"
  type        = string
  default     = "fd8slqa3vkedptmcmgh7"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet in zone A"
  type        = string
  default     = "192.168.10.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR for public subnet in zone B"
  type        = string
  default     = "192.168.20.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR for private subnet in zone A"
  type        = string
  default     = "192.168.30.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR for private subnet in zone B"
  type        = string
  default     = "192.168.40.0/24"
}

variable "vm_preemptible" {
  description = "Use preemptible VMs during development"
  type        = bool
  default     = true
}
