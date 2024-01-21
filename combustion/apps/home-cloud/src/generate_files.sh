#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

cleanup () {
  echo "Caught SIGTERM signal"
  exit 0
}
trap cleanup SIGINT SIGTERM

while true; do
    # avahi aliases for avahi cname
    find /cloud -maxdepth 2 -mindepth 2 -type f -name app.conf |
        xargs grep AVAHI_ALIAS |
        awk -F= '{ print $2 "."; }' |
        tr '\n' ' ' > /cloud/system/avahi_aliases

    # just for information
    ip route show
    echo -n "$(ip route show | grep default | awk '{print $9;}') $(cat /etc/hostname) " > /cloud/system/hosts
    find /cloud -maxdepth 2 -mindepth 2 -type f -name app.conf |
        xargs egrep 'LB_EXTERNAL|LB_INTERNAL' |
        awk -F= '{ print $2; }' |
        tr '\n' ' ' >> /cloud/system/hosts

    # servers list for web ui
    echo -n "[" > /cloud/home-cloud/data/data/home_cloud_site/servers.json
    servers=$(avahi-browse -d local _home_cloud._tcp --resolve -t -p \
    | egrep ^= | awk -F';' '{print "\"http://" $7 ":" $9 "/index.json\"";}' \
    | sort -u | tr '\n' ', ' | sed 's/,$//')
    echo -n "$servers" >> /cloud/home-cloud/data/data/home_cloud_site/servers.json
    echo -n "]" >> /cloud/home-cloud/data/data/home_cloud_site/servers.json

    # servers list for nodes info
    current_server="$(hostname | cut -d"." -f1).local"
    avahi-browse -d local _home_cloud._tcp --resolve -t -p \
    | egrep ^= | awk -F';' '{print "\"https://" $7 ":" $9 "/index.json\"";}' \
    | sort -u | tr -d '"' | grep -v "//$current_server" > /cloud/home-cloud/data/data/home_cloud_site/servers_urls.csv || true

    # apps list for web ui
    echo Nodes info
    ./nodes-info.py

    echo sleeping...
    sleep 60 &
    wait
done
