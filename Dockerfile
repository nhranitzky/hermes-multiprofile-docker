
FROM nousresearch/hermes-agent:latest

USER root
RUN apt-get update && apt-get install -y vim iproute2 supervisor

COPY startup/ /opt/hermes-start/startup/

RUN chmod +x /opt/hermes-start/startup/entrypoint.sh \
             /opt/hermes-start/startup/start.sh \
             /opt/hermes-start/startup/remap-ownership.sh

COPY startup/supervisord.conf /etc/supervisor/supervisord.conf

ENTRYPOINT ["/opt/hermes-start/startup/entrypoint.sh"]
