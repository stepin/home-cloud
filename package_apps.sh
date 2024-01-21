#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

cd combustion
rm -rf apps.tar.gz

cd apps
tar -czvf ../apps.tar.gz .
