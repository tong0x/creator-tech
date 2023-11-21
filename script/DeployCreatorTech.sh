#!/bin/bash
source .env
# export ETHERSCAN_API_KEY=
# export PRIVATE_KEY=
# export CHAIN_ID=1
# export RPC_URL="https://eth.llamarpc.com"
# export VERIFIER_URL="https://api.etherscan.io//api"
export CHAIN_ID=5
export VERIFIER_URL="https://api-goerli.etherscan.io//api"
export SINGER="[0xE6f27ad7e6b7297F7324a0a7d10Dd9b75d2F4d73]"

forge script script/DeployCreatorTech.s.sol:DeployScript \
  --sig "run(address[])()" \
  $SINGER\
  --chain-id "$CHAIN_ID" \
  --rpc-url "$RPC_GOERLI" \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --verifier-url "$VERIFIER_URL" \
  --broadcast \
  --verify \
  --private-key "$PRIVATE_KEY"