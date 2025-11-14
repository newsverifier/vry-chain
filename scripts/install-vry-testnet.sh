#!/bin/bash
# $VRY Testnet — 1-Click Linode Deploy
# https://newsverifier.com

echo "Launching $VRY TESTNET..."

apt update && apt upgrade -y
apt install -y build-essential git curl wget jq make gcc ufw screen nodejs npm

# Go
wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Clone & build
git clone https://github.com/newsverifier/vry-chain.git
cd vry-chain && make build

# Init
./vryd init vry-testnet --chain-id vry-testnet-1

# Genesis
curl -o $HOME/.vry/config/genesis.json https://newsverifier.com/genesis-testnet.json

# Gas
sed -i 's/^minimum-gas-prices =.*/minimum-gas-prices = "0.0001VRY"/' $HOME/.vry/config/app.toml

# Enable 0.1% dynamic fee
echo "tx-fee-percent = 0.001" >> $HOME/.vry/config/app.toml
echo "block-reward-share = 0.5" >> $HOME/.vry/config/app.toml
echo "operator-share = 0.5" >> $HOME/.vry/config/app.toml

# Firewall
ufw allow 22,26656,26657,9090,3000/tcp
ufw --force enable

# Start node
screen -dmS vryd ./vryd start --chain-id vry-testnet-1

# Oracle
curl -o oracle-mock.js https://newsverifier.com/oracle-mock.js
screen -dmS oracle node oracle-mock.js

# Frontend
git clone https://github.com/newsverifier/vry-frontend.git
cd vry-frontend
npm install
echo "REACT_APP_CHAIN_ID=vry-testnet-1" > .env
echo "REACT_APP_RPC=https://newsverifier.com:26657" >> .env
npm run build
screen -dmS frontend serve -s build -l 3000

echo "LIVE: https://newsverifier.com"
echo "Chain ID: vry-testnet-1"
echo "Fee: 0.1% on sends → 0.05% block reward, 0.05% node"
