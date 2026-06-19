locals {
  cloud_init = <<-EOT
    #cloud-config
    users:
      - name: ubuntu
        groups: sudo
        shell: /bin/bash
        sudo: 'ALL=(ALL) NOPASSWD:ALL'
        ssh_authorized_keys:
          - ${file(var.ssh_public_key_path)}
  EOT
}

resource "yandex_compute_instance" "web_server_1" {
  name     = "web-server-1"
  zone     = var.yc_default_zone
  hostname = "web-server-1"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "web"
  }
}

resource "yandex_compute_instance" "web_server_2" {
  name     = "web-server-2"
  zone     = var.yc_default_zone_b
  hostname = "web-server-2"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "web"
  }
}

resource "yandex_compute_instance" "zabbix_vm" {
  name     = "zabbix-vm"
  zone     = var.yc_default_zone
  hostname = "zabbix-vm"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "monitoring"
    role    = "zabbix"
  }
}

resource "yandex_compute_instance" "elasticsearch_vm" {
  name     = "elasticsearch-vm"
  zone     = var.yc_default_zone
  hostname = "elasticsearch-vm"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elasticsearch_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "logs"
    role    = "elasticsearch"
  }
}

resource "yandex_compute_instance" "kibana_vm" {
  name     = "kibana-vm"
  zone     = var.yc_default_zone
  hostname = "kibana-vm"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "logs"
    role    = "kibana"
  }
}

resource "yandex_compute_instance" "bastion" {
  name     = "bastion-host"
  zone     = var.yc_default_zone
  hostname = "bastion-host"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    user-data = local.cloud_init
  }

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  labels = {
    service = "bastion"
  }
}
