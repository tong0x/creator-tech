#!/bin/bash
source .env
# export ETHERSCAN_API_KEY=
# export PRIVATE_KEY=
# export CHAIN_ID=1
# export RPC_URL="https://eth.llamarpc.com"
# export VERIFIER_URL="https://api.etherscan.io//api"
export CHAIN_ID=5
export VERIFIER_URL="https://api-goerli.etherscan.io//api"
export SINGER="[0x55B0023B2f59881f7125f183953a61ee3069833c]"

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