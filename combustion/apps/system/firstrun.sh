#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

chown 10000:10000 /cloud /cloud/*

/cloud/nextcloud/install.sh
/cloud/vaultwarden/install.sh
/cloud/docker-registry/install.sh
/cloud/sonarqube/install.sh
/cloud/gitea/install.sh

/cloud/home-cloud/install.sh
/cloud/system/install.sh
