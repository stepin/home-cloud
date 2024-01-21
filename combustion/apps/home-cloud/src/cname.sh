#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

#/app/go-avahi-cname cname $(cat /system/avahi_aliases)
./go-avahi-cname cname $(cat /cloud/system/avahi_aliases)
