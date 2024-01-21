#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

# avahi service
# check:
# - dig @224.0.0.251 -p 5353 -t ptr +short _home_cloud._tcp.local
# - avahi-resolve --name nas.local
# - macos: dns-sd -B _home_cloud._tcp.local
# - avahi-browse -d local _home_cloud._tcp --resolve -t
cp files/home-cloud.service /etc/avahi/services/

# add backup task
cp files/home-cloud-backup.service /etc/systemd/system/
cp files/home-cloud-backup.timer /etc/systemd/system/

# start new service
systemctl daemon-reload
systemctl enable home-cloud-backup.timer
