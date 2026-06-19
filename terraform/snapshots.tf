resource "yandex_compute_snapshot_schedule" "daily_vm_snapshots" {
  name        = "daily-vm-snapshots"
  description = "Daily snapshots for all diploma VMs"

  schedule_policy {
    expression = "0 15 * * *"
  }

  retention_period = "168h"
  snapshot_count   = 7

  snapshot_spec {
    description = "Daily snapshot from schedule"
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web_server_1.boot_disk[0].disk_id,
    yandex_compute_instance.web_server_2.boot_disk[0].disk_id,
    yandex_compute_instance.elasticsearch_vm.boot_disk[0].disk_id,
    yandex_compute_instance.kibana_vm.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix_vm.boot_disk[0].disk_id,
  ]
}
