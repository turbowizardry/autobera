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

# Execute the command
eval $FORGE_CMD

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
else
    echo "Deployment failed!"
    exit 1
fi 