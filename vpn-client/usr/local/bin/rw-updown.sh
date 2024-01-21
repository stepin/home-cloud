#!/bin/bash
set -eEuo pipefail

XFRM_IF="xfrm${PLUTO_UNIQUEID}"

case "${PLUTO_VERB}" in
    up-client)
        echo "vpn rw-updown" ${PLUTO_VERB} ${PLUTO_UNIQUEID} ${XFRM_IF} ${PLUTO_ME} ${PLUTO_PEER} ${PLUTO_IF_ID_IN} ${PLUTO_IF_ID_OUT}
        ip link add ${XFRM_IF} type xfrm dev lo if_id ${PLUTO_IF_ID_IN}
        ip link set dev ${XFRM_IF} mtu 1418
        ip addr add ${PLUTO_MY_CLIENT} dev ${XFRM_IF}
        ip link set ${XFRM_IF} up
        ip route add default dev ${XFRM_IF}
        nft add rule nat postrouting ip saddr 192.168.100.0/24 oifname "${XFRM_IF}" masquerade
        ;;
    down-client)
	echo down
	    # NOTE: folling command is planned but not supported yet by nft
	    # nft delete rule nat postrouting ip saddr 192.168.100.0/24 oifname "xfrm1" masquerade
	    nft flush chain nat postrouting

	    ip route delete default
	    ip link del ${XFRM_IF}
        ;;
esac
