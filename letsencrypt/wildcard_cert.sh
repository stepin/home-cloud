#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

mkdir -p letsencrypt/config  letsencrypt/work  letsencrypt/logs

certbot certonly \
  --manual \
  --preferred-challenges=dns \
  --email my_email@example.com \
  -d '*.lan.example.com' \
  -d '*.wan.example.com' \
  --config-dir $PWD/letsencrypt/config \
  --work-dir $PWD/letsencrypt/work \
  --logs-dir $PWD/letsencrypt/logs \
  --agree-tos
