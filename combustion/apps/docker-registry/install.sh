#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

source app.conf
APP_FOLDER=$(pwd)

mkdir -p $APP_FOLDER/data/registry $APP_FOLDER/data/certs $APP_FOLDER/data/auth
chown 10000:10000 $APP_FOLDER/data/registry $APP_FOLDER/data/certs $APP_FOLDER/data/auth

# TODO random password
podman run --rm \
  --entrypoint htpasswd \
  httpd:2 -Bbn "$USERNAME" "$PASSWORD" > $APP_FOLDER/data/auth/htpasswd

podman pod create --name docker-registry \
  -p $PUBLIC_PORT:5000

podman run -d --restart always \
  --pod docker-registry --name docker-registry-app \
  --user 10000:10000 \
  -e PUID=10000 \
  -e PGID=10000 \
  -e TZ=$(cat /etc/timezone) \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
  -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -v $APP_FOLDER/data/registry:/var/lib/registry:Z \
  -v $APP_FOLDER/data/certs:/certs:Z \
  -v $APP_FOLDER/data/auth:/auth:z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  registry:2
