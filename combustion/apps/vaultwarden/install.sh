#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

source app.conf
APP_FOLDER=$(pwd)

mkdir -p $APP_FOLDER/data
chown 10000:10000 $APP_FOLDER/data

podman pod create --name vaultwarden \
  -p $PUBLIC_PORT:8080

podman run -d --restart always \
  --pod vaultwarden --name vaultwarden-app \
  --user 10000:10000 \
  -e TZ=$(cat /etc/timezone) \
  -e SIGNUPS_ALLOWED=false \
  -e INVITATIONS_ALLOWED=false \
  -e ROCKET_PORT=8080 \
  -v $APP_FOLDER/data:/data:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  vaultwarden/server
