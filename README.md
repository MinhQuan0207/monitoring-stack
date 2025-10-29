# Déploiement rapide - Stack Monitoring

## Prérequis

- Docker et Docker Compose installés

## 1) Créer le dossier et le fichier

```bash
mkdir monitoring-stack && cd monitoring-stack
nano docker-compose.yml
```

Collez:

```yaml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    container_name: nginx-proxy
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - monitoring
    depends_on:
      - grafana
      - prometheus

  grafana:
    image: mqmqmqmq/cours:grafana
    container_name: grafana
    restart: unless-stopped
    expose:
      - "3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring
    environment:
      - TZ=Europe/Paris
      - VIRTUAL_HOST=tondomaine.duckdns.org
      - VIRTUAL_PORT=3000
      - GF_SERVER_ROOT_URL=http://mqmqmqmq.duckdns.org

  prometheus:
    image: mqmqmqmq/cours:prometheus
    container_name: prometheus
    restart: unless-stopped
    expose:
      - "9090"
    volumes:
      - prometheus_data:/prometheus
    networks:
      - monitoring
    environment:
      - TZ=Europe/Paris

  snmp-exporter:
    image: mqmqmqmq/cours:exporter
    container_name: snmp-exporter
    restart: unless-stopped
    expose:
      - "9116"
    networks:
      - monitoring
    environment:
      - TZ=Europe/Paris

  router:
    image: mqmqmqmq/cours:frr-router
    container_name: frr-router
    hostname: router1
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    networks:
      monitoring:
        ipv4_address: 192.168.100.10
    ports:
      - "161:161/udp"

networks:
  monitoring:
    name: monitoring
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24

volumes:
  prometheus_data:
  grafana_data:
```

## 2) Démarrer

```bash
docker compose up -d
```


## 3) Accès

- Grafana: http://mqmqmqmq.duckdns.org
    - admin / admin123


## 4) Dépannage rapide

- 503: vérifier VIRTUAL_HOST et que grafana tourne
- Datasource 404: s’assurer que l’URL est http://prometheus:9090 dans la datasource et que Prometheus est UP
- Réseau: tous les conteneurs doivent être sur “monitoring”

```bash
docker ps
docker logs nginx-proxy
docker exec grafana wget -qO- http://prometheus:9090/-/healthy
```

