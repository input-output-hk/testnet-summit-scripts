#!/usr/bin/env bash
mkdir -p capstone-work/bin capstone-work/state-node-testnet capstone-work/tarballs
pushd capstone-work
pushd tarballs
if [ ! -f cardano-node-1.29.0-linux.tar.gz ]
then
  echo "Fetching Linux Binaries"
  curl -O -J https://hydra.iohk.io/build/7408438/download/1/cardano-node-1.29.0-linux.tar.gz
fi
if [ ! -f db-testnet-2021-09-23.tar.gz ]
then
  echo "Fetching snapshot"
  curl -O -J https://updates-cardano-testnet.s3.amazonaws.com/cardano-node-state-dir/db-testnet-2021-09-23.tar.gz
fi
popd
if [ ! -f bin/cardano-node ]
then
  echo "extracting binaries"
  tar -zxf tarballs/cardano-node-1.29.0-linux.tar.gz -C bin/
fi
if [ ! -d state-node-testnet/db-testnet ]
then
  echo "extracting snapshot"
  tar -zxf tarballs/db-testnet-2021-09-23.tar.gz -C state-node-testnet/
fi

if [ ! -d config ]
then
  echo "Fetching configuration files"
  mkdir -p config
  curl https://hydra.iohk.io/build/7370192/download/1/testnet-config.json -o config/testnet-config.json
  curl -o config/testnet-byron-genesis.json https://hydra.iohk.io/build/7370192/download/1/testnet-byron-genesis.json
  curl -o config/testnet-shelley-genesis.json https://hydra.iohk.io/build/7370192/download/1/testnet-shelley-genesis.json
  curl -o config/testnet-alonzo-genesis.json https://hydra.iohk.io/build/7370192/download/1/testnet-alonzo-genesis.json
  curl -o config/testnet-topology.json https://hydra.iohk.io/build/7370192/download/1/testnet-topology.json

fi

export PATH=$PATH:$(pwd)/bin
RUNNING=0
if [ -f state-node-testnet/PID ]
then
  ps -p $(<state-node-testnet/PID) > /dev/null
  if [[ $? == 0 ]]
  then
    RUNNING=1
    echo "cardano-node is already running"
  fi
fi
if [[ "$RUNNING" -eq 0 ]]
then
  echo "Starting cardano-node"
  rm -f state-node-testnet/node.socket
  nohup cardano-node run --config config/testnet-config.json --database-path state-node-testnet/db-testnet --topology config/testnet-topology.json --host-addr 0.0.0.0 --port 3001 --socket-path state-node-testnet/node.socket +RTS -N2 -A16m -qg -qb --disable-delayed-os-memory-return -RTS > state-node-testnet/cardano-node.log 2>&1 &
  echo $! > state-node-testnet/PID
  echo "Node started!"
  echo "Logs can be found at $(pwd)/state-node-testnet/cardano-node.log"
else
  echo "Node already running with PID $(<state-node-testnet/PID)"
fi
export CARDANO_NODE_SOCKET_PATH=$(pwd)/state-node-testnet/node.socket

echo "Waiting for socket to start"
while true
do
  if [ -S state-node-testnet/node.socket ]
  then
    break
  fi
  sleep 1;
done

while true
do
  PROGRESS=$(cardano-cli query tip --testnet-magic 1097911063|jq -r .syncProgress)
  if [[ "$PROGRESS" != "100.00" ]]
  then
    echo "Current sync progress: $PROGRESS"
  else
    break
  fi
  sleep 5;
done

echo "Node successfully setup and synced. Type exit to stop"
cardano-cli --bash-completion-script cardano-cli > bin/cli-completion
bash --init-file bin/cli-completion
echo "Stopping node"
kill -INT $(<state-node-testnet/PID)
