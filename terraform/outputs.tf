output "alb_public_ip" {
  description = "Public IP address of the Application Load Balancer"
  value       = yandex_alb_load_balancer.web_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "bastion_host_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "zabbix_vm_public_ip" {
  description = "Public IP address of the Zabbix VM"
  value       = yandex_compute_instance.zabbix_vm.network_interface.0.nat_ip_address
}

output "kibana_vm_public_ip" {
  description = "Public IP address of the Kibana VM"
  value       = yandex_compute_instance.kibana_vm.network_interface.0.nat_ip_address
}

output "web_server_1_fqdn" {
  description = "FQDN of Web Server 1"
  value       = yandex_compute_instance.web_server_1.fqdn
}

output "web_server_2_fqdn" {
  description = "FQDN of Web Server 2"
  value       = yandex_compute_instance.web_server_2.fqdn
}

output "elasticsearch_vm_fqdn" {
  description = "FQDN of Elasticsearch VM"
  value       = yandex_compute_instance.elasticsearch_vm.fqdn
}

output "zabbix_vm_fqdn" {
  description = "FQDN of Zabbix VM"
  value       = yandex_compute_instance.zabbix_vm.fqdn
}

output "kibana_vm_fqdn" {
  description = "FQDN of Kibana VM"
  value       = yandex_compute_instance.kibana_vm.fqdn
}
