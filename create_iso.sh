#!/usr/bin/env bash
set -eEuo pipefail
cd "$(dirname "$0")"
set -x

rm -rf microos-combustion-home-server.iso iso.tmp

mkdir -p iso.tmp/combustion
cp home-server/script iso.tmp/combustion/
cp ~/.ssh/id_rsa.pub iso.tmp/

mkisofs -l -o microos-combustion-home-server.iso -V combustion iso.tmp
rm -rf iso.tmp
