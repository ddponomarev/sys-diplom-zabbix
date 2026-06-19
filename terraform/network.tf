resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "main-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = var.yc_default_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_subnet" "public_subnet_b" {
  name           = "public-subnet-b"
  zone           = var.yc_default_zone_b
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr_b]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_subnet" "private_subnet_a" {
  name           = "private-subnet-a"
  zone           = var.yc_default_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr_a]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_subnet" "private_subnet_b" {
  name           = "private-subnet-b"
  zone           = var.yc_default_zone_b
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr_b]
  route_table_id = yandex_vpc_route_table.route_table.id
}

resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for Bastion Host"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix Server to get metrics"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet.v4_cidr_blocks[0],
      yandex_vpc_subnet.public_subnet_b.v4_cidr_blocks[0],
    ]
    port = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTPS from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "ANY"
    description       = "Health checks"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "load_balancer_healthchecks"
  }

  egress {
    protocol       = "TCP"
    description    = "Allow HTTP to web-server-1 subnet"
    v4_cidr_blocks = [yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0]]
    from_port      = 80
    to_port        = 80
  }

  egress {
    protocol       = "TCP"
    description    = "Allow HTTP to web-server-2 subnet"
    v4_cidr_blocks = [yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]]
    from_port      = 80
    to_port        = 80
  }
}

resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for Web Servers"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from Bastion Host"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow HTTP from ALB"
    security_group_id = yandex_vpc_security_group.alb_sg.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Nginx stub_status from Zabbix Server"
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Zabbix Server to get metrics"
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
    port              = 10050
  }

  egress {
    protocol       = "TCP"
    description    = "Send logs to Elasticsearch"
    v4_cidr_blocks = [yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0]]
    port           = 9200
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "zabbix_sg" {
  name        = "zabbix-sg"
  description = "Security group for Zabbix VM"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from Bastion Host"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP access for Zabbix UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix Agents for Active Checks"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet.v4_cidr_blocks[0],
      yandex_vpc_subnet.public_subnet_b.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0],
    ]
    port = 10051
  }

  egress {
    protocol       = "TCP"
    description    = "Allow Zabbix Server to get metrics from web"
    v4_cidr_blocks = [
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0],
    ]
    port = 10050
  }

  egress {
    protocol       = "TCP"
    description    = "Allow Zabbix Server to get metrics from elasticsearch"
    v4_cidr_blocks = [yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0]]
    port           = 10050
  }

  egress {
    protocol       = "TCP"
    description    = "Allow Zabbix Server to get metrics from kibana"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet.v4_cidr_blocks[0],
      yandex_vpc_subnet.public_subnet_b.v4_cidr_blocks[0],
    ]
    port = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch VM"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from Bastion Host"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Kibana to access Elasticsearch"
    security_group_id = yandex_vpc_security_group.kibana_sg.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Web servers to send logs to Elasticsearch"
    security_group_id = yandex_vpc_security_group.web_sg.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Zabbix Server to get metrics"
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
    port              = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-sg"
  description = "Security group for Kibana VM"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from Bastion Host"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP access to Kibana from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Zabbix Server to get metrics"
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
    port              = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
