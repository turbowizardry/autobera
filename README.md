# AutoBera

A flexible and secure smart contract wallet that automates PoL activities on Berachain. Whilst liquid BGT is cool, I'm biased in owning native BGT to maximise returns, control your votes, and overall be a very savvy Bera. You own the contract and give permissions to controllers to automate tasks on your behalf.

## Features

- Auto-claim BGT
- Auto-boost your preferred validator
- Auto-claim your incentives
- Auto-swap your incentives to your preferred token
- Delegate your earned BGT for governance

## Contract Structure

- `Wallet.sol`: Main wallet implementation
- `WalletFactory.sol`: Factory contract for deploying new wallets
- `ControllerRegistry.sol`: Registry for controller contracts with specific functions

## Usage

### Owner Operations

```solidity
// Transfer BERA
wallet.ownerExecute(recipient, amount, "");

// Transfer ERC20 / LP Tokens
wallet.ownerExecute(tokenAddress, 0, transferData);

// Transfer NFTs
wallet.ownerExecute(nftAddress, 0, transferData);
```

### Controller Operations

```solidity
// Execute token operations (requires TOKEN_OPERATIONS permission)
wallet.controllerExecute(target, data, TOKEN_OPERATIONS, value);
```

## Testing

Run tests using Foundry:
```bash
forge test
```

## License

MIT
