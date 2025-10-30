FROM prom/prometheus:v3.5.0 AS prometheus_mq
COPY ./prometheus/prometheus.yml /etc/prometheus/prometheus.yml
EXPOSE 9090
VOLUME ["/prometheus"]
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--storage.tsdb.retention.time=30d", \
     "--web.enable-lifecycle"]


FROM prom/snmp-exporter:v0.29.0 AS exporter_mq
COPY ./snmp-exporter/snmp.yml /etc/snmp_exporter/snmp.yml
EXPOSE 9116
CMD ["--config.file=/etc/snmp_exporter/snmp.yml"]


FROM grafana/grafana:11.6.6 AS grafana_mq
COPY ./grafana/dashboards/ /etc/grafana/provisioning/dashboards/
COPY ./grafana/datasources/ /etc/grafana/provisioning/datasources/
ENV GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_ADMIN_PASSWORD=admin123 \
    GF_USERS_ALLOW_SIGN_UP=false \
    GF_ANALYTICS_REPORTING_ENABLED=false \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false
EXPOSE 3000
VOLUME ["/var/lib/grafana"]
USER grafana


FROM frrouting/frr:v8.4.1 AS router_mq
USER root
RUN apk add --no-cache net-snmp net-snmp-tools supervisor
COPY ./router/daemons /etc/frr/daemons
COPY ./router/frr.conf /etc/frr/frr.conf
COPY ./router/snmpd.conf /etc/snmp/snmpd.conf
RUN mkdir -p /var/agentx && \
    chown frr:frr /var/agentx && \
    chmod 755 /var/agentx && \
    chown -R frr:frr /etc/frr && \
    chmod 640 /etc/frr/frr.conf
COPY ./router/supervisord.conf /etc/supervisord.conf
EXPOSE 161/udp 162/udp 179

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
