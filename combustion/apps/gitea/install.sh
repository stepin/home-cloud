#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

source app.conf
APP_FOLDER=$(pwd)

mkdir -p $APP_FOLDER/data/mysql $APP_FOLDER/data/gitea/data $APP_FOLDER/data/gitea/config
chown 10000:10000 $APP_FOLDER/data/mysql $APP_FOLDER/data/gitea/data $APP_FOLDER/data/gitea/config

podman pod create --name gitea \
  -p $PUBLIC_PORT:3000

podman run -d --restart always \
  --pod gitea --name gitea-db \
  --user 10000:10000 \
  -e "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_USER=gitea \
  -e "MYSQL_PASSWORD=$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE=gitea \
  -e TZ=$(cat /etc/timezone) \
  -v $APP_FOLDER/data/mysql:/var/lib/mysql:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  mysql:8

podman run -d --restart always \
  --pod gitea --name gitea-app \
  --user 10000:10000 \
  -e USER=10000 \
  -e GITEA__server__START_SSH_SERVER=false \
  -e GITEA__database__DB_TYPE=mysql \
  -e GITEA__database__HOST=localhost:3306 \
  -e GITEA__database__NAME=gitea \
  -e GITEA__database__USER=gitea \
  -e "GITEA__database__PASSWD=$MYSQL_PASSWORD" \
  -e TZ=$(cat /etc/timezone) \
  -v $APP_FOLDER/data/gitea/data:/var/lib/gitea:Z \
  -v $APP_FOLDER/data/gitea/config:/etc/gitea:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  gitea/gitea:1.21-rootless
