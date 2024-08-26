#!/usr/bin/env sh

FORCE=${FORCE:-"false"}

CHAIN_TYPE=${CHAIN_TYPE:-"mainnet"}

POLKACHU_SECRET=${POLKACHU_SECRET:-""}
SNAPSHOT_PROVIDER=${SNAPSHOT_PROVIDER:-"polkachu"}


if [ "${FORCE}" = "true" ]; then
    cp -v ${DAEMON_HOME}/data/priv_validator_state.json ${DAEMON_HOME}
    ${DAEMON_NAME} tendermint unsafe-reset-all --keep-addr-book
fi

if [ -f "${DAEMON_HOME}/data/priv_validator_state.json" ]; then
    echo "Data already provided, please start with FORCE=true to reset"
    exit 1
fi

case "${SNAPSHOT_PROVIDER}" in
    "polkachu")
        echo "Getting snapshots from polkachu.com"
        SNAP_INFO=$(curl -s -H "x-polkachu: ${POLKACHU_SECRET}" https://polkachu.com/api/v2/chain_snapshots/${CHAIN_NAME}/${CHAIN_TYPE} | jq)
        curl -o - -L $(echo $SNAP_INFO | jq -r ".snapshot.url") | lz4 -c -d - | tar -x -C $DAEMON_HOME
        ;;
    "nodestake.top")
        SNAP_NAME=$(curl -s https://ss.teritori.nodestake.top/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
        curl -o - -L https://ss.teritori.nodestake.top/${SNAP_NAME}  | lz4 -c -d - | tar -x -C $DAEMON_HOME
        ;;
    "nysa.network")
        echo "TODO"
        ;;
    "*")
        curl -o - -L ${URL} | lz4 -c -d - | tar -x -C $DAEMON_HOME
        ;;
esac
