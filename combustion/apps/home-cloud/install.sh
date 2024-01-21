#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

APP_FOLDER=$(pwd)

# TODO:
# 1. app that will find _home_cloud._tcp.local services and generate json
# 2. generate index.html / index.json / Caddyfile from file system (/cloud)

mkdir -p $APP_FOLDER/data/config $APP_FOLDER/data/data
chown -R 10000:10000 $APP_FOLDER/data/config $APP_FOLDER/data/data

./build.sh

podman pod create --name home-cloud \
  -p 80:80 \
  -p 443:443 \
  -p 8443:8443 \
  -p 8080:8080

# LB and home page
podman run -d --restart always \
  --pod home-cloud --name home-cloud-lb \
  --user 10000:10000 \
  -e TZ=$(cat /etc/timezone) \
  -v $APP_FOLDER/data/config:/config:z \
  -v $APP_FOLDER/data/data:/data:z \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  caddy:2-alpine \
  caddy run --environ --config /config/Caddyfile

# NOTE: docker for mDNS don't work properly even with host network, so, switched to local services for now

cp files/home-cloud-cname.service files/home-cloud-config-gen.service /etc/systemd/system
systemctl daemon-reload
systemctl enable --now home-cloud-cname home-cloud-config-gen

# transactional-update pkg in avahi-utils

# app that will find _home_cloud._tcp.local services and generate json
# NOTE: for avahi-browser user 10000 is not used
#podman run -d --restart always \
#  --name home-cloud-files-gen \
#  --network host \
#  -e TZ=$(cat /etc/timezone) \
#  -v $APP_FOLDER/data/config:/config:z \
#  -v $APP_FOLDER/data/data:/data:z \
#  -v /cloud:/cloud:z \
#  -v /etc/hostname:/host-hostname:ro \
#  -v /var/run/dbus:/var/run/dbus:z \
#  -v /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket:z \
#  -v /etc/localtime:/etc/localtime:ro \
#  -v /etc/timezone:/etc/timezone:ro \
#  home-cloud \
#  /app/generate_files.sh

# NOTE: this one is without pod as it uses host network
#podman run -d --restart always \
#  --name home-cloud-avahi-cname \
#  --network host \
#  -v "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:z" \
#  -v /cloud/system:/system:z \
#  home-cloud \
#  /app/cname.sh

