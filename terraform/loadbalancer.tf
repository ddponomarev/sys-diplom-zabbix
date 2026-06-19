resource "yandex_alb_target_group" "web_target_group" {
  name = "web-target-group"

  target {
    ip_address = yandex_compute_instance.web_server_1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
  }

  target {
    ip_address = yandex_compute_instance.web_server_2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private_subnet_b.id
  }
}

resource "yandex_alb_backend_group" "web_backend" {
  name = "web-backend"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]

    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      unhealthy_threshold = 2
      healthy_threshold   = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web_host" {
  name           = "web-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "main-route"

    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }

      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_balancer" {
  name       = "web-balancer"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = var.yc_default_zone
      subnet_id = yandex_vpc_subnet.public_subnet.id
    }

    location {
      zone_id   = var.yc_default_zone_b
      subnet_id = yandex_vpc_subnet.public_subnet_b.id
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }

      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  security_group_ids = [yandex_vpc_security_group.alb_sg.id]
}
