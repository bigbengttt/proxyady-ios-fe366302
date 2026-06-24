#!/usr/bin/env bash
set -e
pkill -f "Server_IPA_SESSION.py" 2>/dev/null || true
for p in 8088 8091 8092 8093 8094 8095 8096 8097; do
  nohup /root/venv_proxy/bin/mitmdump \
    -s /root/Server_IPA_SESSION.py \
    --set listen_port=$p \
    --set block_global=false \
    --set keep_host_header=false \
    --set http2=false \
    --set ssl_insecure=true \
    --set connection_strategy=lazy \
    > /root/ipa_$p.log 2>&1 &
done
sleep 2
ss -tulpen | egrep ':8088|:8091|:8092|:8093|:8094|:8095|:8096|:8097'
