#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

source app.conf
APP_FOLDER=$(pwd)

mkdir -p $APP_FOLDER/data/mysql $APP_FOLDER/data/redis $APP_FOLDER/data/nextcloud
chown 10000:10000 $APP_FOLDER/data/mysql $APP_FOLDER/data/redis $APP_FOLDER/data/nextcloud

podman pod create --name nextcloud \
  -p $PUBLIC_PORT:80

podman run -d --restart always \
  --pod nextcloud --name nextcloud-db \
  --user 10000:10000 \
  -e "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_USER=nextcloud \
  -e "MYSQL_PASSWORD=$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE=nextcloud \
  -e TZ=$(cat /etc/timezone) \
  -v $PWD/data/mysql:/var/lib/mysql:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  mysql:8 \
  --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW

podman run -d --restart always \
  --pod nextcloud --name nextcloud-redis \
  --user 10000:10000 \
  -e TZ=$(cat /etc/timezone) \
  -v $PWD/data/redis:/data:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  redis:alpine

# NOTE: These environment variables are only read in on the initial setup of nextcloud.
# After that, you have to edit the config.php file.
# I.e. if $APP_FOLDER/data/nextcloud is not empty env vars will be ignored.
podman run -d --restart always \
  --pod nextcloud --name nextcloud-app \
  -e MYSQL_HOST=127.0.0.1 \
  -e MYSQL_ROOT_PASSWORD=nextcloud \
  -e MYSQL_USER=nextcloud \
  -e "MYSQL_PASSWORD=$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE=nextcloud \
  -e REDIS_HOST=localhost \
  -e TZ=$(cat /etc/timezone) \
  -e "NEXTCLOUD_TRUSTED_DOMAINS=${AVAHI_ALIAS:-} ${LB_INTERNAL:-} ${LB_EXTERNAL:-}" \
  -v $APP_FOLDER/data/nextcloud:/var/www/html:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  nextcloud
