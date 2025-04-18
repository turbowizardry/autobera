# AutoBera API Documentation

This API provides endpoints for interacting with the AutoBera system, including vault management, controller permissions, and automated claiming functionality.

## Environment Variables

```env
DATABASE_URL="postgresql://user:password@localhost:5432/autobera"
WALLET_PRIVATE_KEY="your_private_key_here"
CRON_SECRET="your_cron_secret_here"
```

## API Endpoints

### Vaults

#### GET /api/vaults
Fetches all vaults and their current status.

Query Parameters:
- `network` (optional): 'mainnet' or 'testnet' (default: 'mainnet')
- `userAddress` (optional): Address to check earned amounts for
- `walletAddress` (optional): Address to check operator status for

Response:
```json
{
  "vaults": [
    {
      "id": "string",
      "vaultAddress": "0x...",
      "name": "string",
      "protocol": "string",
      "logoURI": "string",
      "earned": "string",
      "isOperator": boolean
    }
  ]
}
```

### Controllers

#### GET /api/controllers
Fetches all controllers and their permissions for a wallet.

Query Parameters:
- `network` (optional): 'mainnet' or 'testnet' (default: 'mainnet')
- `walletAddress` (required): Address to check permissions for

Response:
```json
{
  "controllers": [
    {
      "id": "string",
      "address": "0x...",
      "name": "string",
      "permissionKey": "string",
      "description": "string",
      "isActive": boolean,
      "isApproved": boolean,
      "approvedAt": "string"
    }
  ]
}
```

## Cron Jobs

### Claim Check (/api/cron/claim)
- Schedule: Every 5 hours
- Function: Checks all active wallets with auto-claim permissions and triggers claims for any earned rewards
- Authorization: Required via `CRON_SECRET` environment variable

To trigger manually:
```bash
curl -X GET http://localhost:3000/api/cron/claim \
  -H "Authorization: Bearer your_cron_secret_here"
```

## Database Schema

The API uses Prisma with PostgreSQL. Key models include:

- Vault: Stores vault information and cached data
- VaultOperator: Tracks operator relationships
- Controller: Stores controller information
- WalletPermission: Tracks wallet permissions for controllers

To initialize the database:
```bash
npx prisma migrate dev
```

To update the database schema:
```bash
npx prisma generate
``` 