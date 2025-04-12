import { useChainId } from 'wagmi'
import contracts from '@/data/contracts.json'

type NetworkKey = 'berachain' | 'testnet'

interface ContractAddresses {
  ControllerRegistry: {
    address: string
  }
  WalletPermissions: {
    address: string
  }
  WalletFactory: {
    address: string
  }
  Wallet: {
    address: string
  }
  RewardVaultFactory?: {
    address: string
  }
  controllers: {
    ClaimBGTController: {
      address: string
    }
  }
}

export function useContracts() {
  const chainId = useChainId()
  
  const getNetworkKey = (): NetworkKey => {
    // Default to berachain if no chain selected
    if (!chainId) return 'berachain'
    // You can add more chain ID checks here if needed
    if (chainId === 80069) return 'testnet'
    
    return 'berachain'
  }

  const networkKey = getNetworkKey()
  const networkContracts = contracts.networks[networkKey]?.contracts as ContractAddresses

  if (!networkContracts) {
    console.warn(`No contracts found for network: ${networkKey}`)
    return null
  }

  return {
    controllerRegistry: networkContracts.ControllerRegistry.address,
    walletPermissions: networkContracts.WalletPermissions.address,
    walletFactory: networkContracts.WalletFactory.address,
    wallet: networkContracts.Wallet.address,
    rewardVaultFactory: networkContracts.RewardVaultFactory?.address,
    controllers: networkContracts.controllers
  }
} 