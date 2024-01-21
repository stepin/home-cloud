#!/usr/bin/env bash
#
# Backups data to NAS.
#
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

# stop all containers to be sure that files are in a consistent state
# podman stop --all

# it will be cloud-lan-srv for cloud.lan hostname
backup_nas_user="$(hostname | tr . -)-srv"

# sync /cloud folder as backup
cd /
rsync -avz --delete /cloud "${backup_nas_user}@mynas:"

# restart all containers
# podman start --all
