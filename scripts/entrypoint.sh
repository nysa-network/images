#!/usr/bin/env sh

set -ex

LOG_FORMAT=${LOG_FORMAT:-"json"}
LOG_LEVEL=${LOG_LEVEL:-"info"}

MONIKER=${MONIKER:-"node"}

MINIMUM_GAS_PRICES=${MINIMUM_GAS_PRICES:-""}

PRUNING=${PRUNING:-"default"}
PRUNING_KEEP_RECENT=${PRUNING_KEEP_RECENT:-"0"}
PRUNING_KEEP_EVERY=${PRUNING_KEEP_EVERY:-"0"}
PRUNING_INTERVAL=${PRUNING_INTERVAL:-"0"}

STATESYNC_SNAPSHOT_INTERVAL=${STATESYNC_SNAPSHOT_INTERVAL:-"0"}
STATESYNC_SNAPSHOT_KEEP_RECENT=${STATESYNC_SNAPSHOT_KEEP_RECENT:-"0"}

INDEXER=${INDEXER:-"kv"}

P2P_SEEDS=${P2P_SEEDS:-""}
P2P_PEERS=${P2P_PEERS:-""}
P2P_EXTERNAL_ADDR=${P2P_EXTERNAL_ADDR:-""}

P2P_LADDR=${P2P_LADDR:-"tcp://0.0.0.0:26656"}
RPC_LADDR=${RPC_LADDR:-"tcp://0.0.0.0:26657"}
GRPC_LADDR=${GRPC_LADDR:-""}

PROMETHEUS_ENABLED=${PROMETHEUS_ENABLED:-"false"}
PROMETHEUS_LISTEN_ADDR=${PROMETHEUS_LISTEN_ADDR:-":26660"}

sed -i "s#moniker = .*#moniker = \"${MONIKER}\"#g" $DAEMON_HOME/config/config.toml

sed -i "s#^minimum-gas-prices = .*#minimum-gas-prices = \"${MINIMUM_GAS_PRICES}\"#g" $DAEMON_HOME/config/app.toml

sed -i "s#indexer = .*#indexer = \"$INDEXER\"#g" $DAEMON_HOME/config/config.toml
# MUST be grpc.address in app.toml
#sed -i "s#grpc_laddr =.*#grpc_laddr = \"$GRPC_LADDR\"#g" $DAEMON_HOME/config/config.toml

sed -i "s#^pruning = .*#pruning = \"${PRUNING}\"#g" $DAEMON_HOME/config/app.toml
sed -i "s#^pruning-keep-recent = .*#pruning-keep-recent = \"${PRUNING_KEEP_RECENT}\"#g" $DAEMON_HOME/config/app.toml
sed -i "s#^pruning-keep-every = .*#pruning-keep-every = \"${PRUNING_KEEP_EVERY}\"#g" $DAEMON_HOME/config/app.toml
sed -i "s#^pruning-interval = .*#pruning-interval = \"${PRUNING_INTERVAL}\"#g" $DAEMON_HOME/config/app.toml

sed -i "s#^snapshot-interval =.*#snapshot-interval = ${STATESYNC_SNAPSHOT_INTERVAL}#" $DAEMON_HOME/config/app.toml
sed -i "s#^snapshot-keep-recent =.*#snapshot-keep-recent = ${STATESYNC_SNAPSHOT_KEEP_RECENT}#" $DAEMON_HOME/config/app.toml

sed -i "s#^seeds = .*#seeds = \"${P2P_SEEDS}\"#g"                        $DAEMON_HOME/config/config.toml
sed -i "s#^persistent_peers = .*#persistent_peers = \"${P2P_PEERS}\"#g" $DAEMON_HOME/config/config.toml

sed -i "s#external_address =.*#external_address = \"$P2P_EXTERNAL_ADDR\"#g" $DAEMON_HOME/config/config.toml

sed -i "s#^prometheus = .*#prometheus = ${PROMETHEUS_ENABLED}#g" $DAEMON_HOME/config/config.toml
sed -i "s#^prometheus_listen_addr = .*#prometheus_listen_addr = \"${PROMETHEUS_LISTEN_ADDR}\"#g" $DAEMON_HOME/config/config.toml

for file in /entrypoint.d/*.sh; do
     bash "$file" || true
done

exec /usr/bin/${DAEMON_NAME} start \
    --home=${DAEMON_HOME} \
    --rpc.laddr="${RPC_LADDR}" \
    --p2p.laddr="${P2P_LADDR}" \
    --log_level=$LOG_LEVEL
