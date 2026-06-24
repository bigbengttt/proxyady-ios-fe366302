#!/usr/bin/env bash
set -e
DOMINIO="${1:-https://proxybrasil2026.io.vn}"
DOMINIO="${DOMINIO%/}"
# Roda na raiz do projeto antes de enviar para o bot/GitHub
sed -i "s#https://SEU_DOMINIO_DA_servidor.com/api#${DOMINIO}/api#g" ios/ProxyADY/ProxyADY/Config.swift
sed -i "s#https://SEU_DOMINIO_DA_servidor.com#${DOMINIO}#g" backend/data/app_config.json
printf "OK: projeto apontando para %s\n" "$DOMINIO"
