# Дипломная работа по профессии «Системный администратор»

**Выполнил:** Пономарев Денис

**Задание:** https://github.com/netology-code/sys-diplom/tree/diplom-zabbix

## Решение

Развёрнута отказоустойчивая инфраструктура в Yandex Cloud с помощью Terraform и Ansible.

### Архитектура

| Компонент | Роль | Подсеть | Зона |
|-----------|------|---------|------|
| bastion-host | SSH jump host | public | ru-central1-a |
| web-server-1 | Nginx + Filebeat + Zabbix Agent | private | ru-central1-a |
| web-server-2 | Nginx + Filebeat + Zabbix Agent | private | ru-central1-b |
| zabbix-vm | Zabbix Server + UI | public | ru-central1-a |
| elasticsearch-vm | Elasticsearch (Docker) | private | ru-central1-a |
| kibana-vm | Kibana (Docker) | public | ru-central1-a |
| web-balancer | Application Load Balancer | public | ru-central1-a/b |

### Структура репозитория

```text
terraform/   # VPC, VM, ALB, snapshots
ansible/     # конфигурация сервисов
materials/   # скриншоты
```

## Доступ к сервисам

| Сервис | Адрес |
|--------|-------|
| Сайт (ALB) | http://158.160.192.89/ |
| Bastion (SSH) | 111.88.240.115 |
| Zabbix UI | http://111.88.241.121:8080/ |
| Kibana | http://51.250.85.23:5601/ |

**Zabbix:** логин `Admin`, пароль `xxxx`
curl <http://158.160.192.89/`>

## Сайт

- Два идентичных web-сервера в зонах `ru-central1-a` и `ru-central1-b`.
- Web-серверы во внутренней сети без публичного IP.
- Доступ через Application Load Balancer.
- SSH к web-серверам только через bastion host.

### Балансировщик

1. Target Group с двумя web-серверами
2. Backend Group с healthcheck на `/` порт 80
3. HTTP Router с маршрутом `/`
4. Application Load Balancer listener auto:80

Проверка:

```bash
curl -v http://158.160.192.89/
```

## Мониторинг

- Zabbix Server на отдельной ВМ в публичной подсети.
- Zabbix Agent на всех ВМ.
- Хосты объединены в группу `Diplom`.
- Шаблон `Linux by Zabbix agent` — на всех хостах.
- Шаблон `Nginx by HTTP` — на web-server-1 и web-server-2.

### Dashboard USE Infrastructure

Настроен  после первого входа в Zabbix:

1. Все хосты добавлены в host group `Diplom`.
2. Применён шаблон `Linux by Zabbix agent`.
3. Для web-серверов добавлен шаблон `Nginx by HTTP`
4. Создан dashboard `USE Infrastructure` с виджетами:
   - CPU utilization
   - Memory utilization
   - Disk utilization
   - Network traffic
   - Nginx requests
5. Thresholds на графиках: CPU > 80%, RAM > 85%, disk > 90%.

Скриншоты: `materials/zabbix/`

## Логи

- Elasticsearch в приватной подсети (Docker).
- Filebeat на web-серверах отправляет `/var/log/nginx/*.log` в Elasticsearch.
- Kibana в публичной подсети подключена к Elasticsearch.

Пример конфигурации Filebeat:

```yaml
filebeat.inputs:
- type: filestream
  id: nginx-logs
  paths:
    - /var/log/nginx/*.log
  fields:
    log_source: nginx-docker-host
  tags: ["nginx-logs", "nginx"]

output.elasticsearch:
  hosts: ["http://elasticsearch-vm.ru-central1.internal:9200"]
```

Просмотр логов в Kibana: **Discover** → data view `filebeat-*` → фильтр `tags: nginx`.

Скриншоты: `materials/kibana/`

## Сеть

- Один VPC с NAT gateway для исходящего трафика из приватных подсетей.
- Security Groups ограничивают входящий трафик нужными портами.
- Bastion host — единственная точка SSH-доступа из интернета (порт 22).

Скриншоты: `materials/network/`, `materials/bastion/`

## Резервное копирование

- Snapshot  для всех boot-дисков ВМ.
- Ежедневное создание snapshot.
- Хранение 7 дней .

Скриншоты: `materials/snapshots/`


## Скриншоты

Все скриншоты для проверки — в каталоге `materials/`:

- `materials/vm/` — список ВМ
- `materials/nginx/` — nginx на web-серверах
- `materials/balancer/` — ALB, target/backend groups, curl
- `materials/zabbix/` — UI и dashboard USE
- `materials/elasticsearch/` — контейнер Elasticsearch
- `materials/kibana/` — UI Kibana и логи nginx
- `materials/network/` — VPC, подсети, security groups
- `materials/bastion/` — bastion SG
- `materials/snapshots/` — расписание snapshot
