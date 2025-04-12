#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please create one with your PRIVATE_KEY"
    exit 1
fi

# Default values
NETWORK="testnet"
RPC_URL=""
VERIFY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        --verify)
            VERIFY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set RPC URL based on network if not provided
if [ -z "$RPC_URL" ]; then
    case $NETWORK in
        "testnet")
            RPC_URL="https://80069.rpc.thirdweb.com/${THIRDWEB_ID}"
            ;;
        "mainnet")
            RPC_URL="https://80094.rpc.thirdweb.com/${THIRDWEB_ID}"
            ;;
        *)
            echo "Error: Unknown network or RPC URL not provided"
            exit 1
            ;;
    esac
fi

echo "Deploying to $NETWORK network..."

# Build the forge command
FORGE_CMD="forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast"

# Add verification if requested
if [ "$VERIFY" = true ]; then
    FORGE_CMD="$FORGE_CMD --verify"
fi

# Create a temporary file to store the deployment output
TEMP_OUTPUT=$(mktemp)

# Execute the command and capture output
eval $FORGE_CMD | tee $TEMP_OUTPUT

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
    
    # Extract contract addresses from the output
    CONTROLLER_REGISTRY=$(grep "ControllerRegistry deployed at:" $TEMP_OUTPUT | awk '{print $NF}')
    WALLET_PERMISSIONS=$(grep "WalletPermissions deployed at:" $TEMP_OUTPUT | awk '{print $NF}')
    WALLET_IMPL=$(grep "Wallet implementation deployed at:" $TEMP_OUTPUT | awk '{print $NF}')
    WALLET_FACTORY=$(grep "WalletFactory deployed at:" $TEMP_OUTPUT | awk '{print $NF}')
    CLAIM_BGT_CONTROLLER=$(grep "ClaimBGTController deployed at:" $TEMP_OUTPUT | awk '{print $NF}')
    
    # Path to the contracts.json file
    CONTRACTS_JSON="../data/contracts.json"
    
    # Update the contracts.json file
    jq --arg network "$NETWORK" \
       --arg controller_registry "$CONTROLLER_REGISTRY" \
       --arg wallet_permissions "$WALLET_PERMISSIONS" \
       --arg wallet_impl "$WALLET_IMPL" \
       --arg wallet_factory "$WALLET_FACTORY" \
       --arg claim_bgt_controller "$CLAIM_BGT_CONTROLLER" \
       '.networks[$network].contracts.ControllerRegistry.address = $controller_registry |
        .networks[$network].contracts.WalletPermissions.address = $wallet_permissions |
        .networks[$network].contracts.Wallet.address = $wallet_impl |
        .networks[$network].contracts.WalletFactory.address = $wallet_factory |
        .networks[$network].contracts.controllers.ClaimBGTController.address = $claim_bgt_controller' \
       "$CONTRACTS_JSON" > tmp.json && mv tmp.json "$CONTRACTS_JSON"
    
    echo "Updated contracts.json with new deployment addresses"

    # Copy ABIs to the frontend
    echo "Copying ABIs to frontend..."
    cp out/ControllerRegistry.sol/ControllerRegistry.json ../abi/
    cp out/WalletPermissions.sol/WalletPermissions.json ../abi/
    cp out/Wallet.sol/Wallet.json ../abi/
    cp out/WalletFactory.sol/WalletFactory.json ../abi/
    cp out/controllers/ClaimBGTController.sol/ClaimBGTController.json ../abi/
    echo "ABIs copied successfully!"
else
    echo "Deployment failed!"
    exit 1
fi

# Clean up
rm $TEMP_OUTPUT 