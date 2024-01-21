#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

source app.conf
APP_FOLDER=$(pwd)

mkdir -p $APP_FOLDER/data/data $APP_FOLDER/data/logs $APP_FOLDER/data/extensions
chown 10000:10000 $APP_FOLDER/data/data $APP_FOLDER/data/logs $APP_FOLDER/data/extensions

podman pod create --name sonarqube \
  -p $PUBLIC_PORT:9000

podman run -d --restart always \
  --pod sonarqube --name sonarqube-app \
  --user 10000:10000 \
  --stop-timeout 3600 \
  -e TZ=$(cat /etc/timezone) \
  -v $APP_FOLDER/data/data:/opt/sonarqube/data:Z \
  -v $APP_FOLDER/data/logs:/opt/sonarqube/logs:Z \
  -v $APP_FOLDER/data/extensions:/opt/sonarqube/extensions:Z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  sonarqube:community
