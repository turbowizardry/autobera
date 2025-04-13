import { useChainId } from 'wagmi'
import contracts from '@/data/contracts.json'
import berachainContracts from '@/data/berachain.json'

type NetworkKey = 'mainnet' | 'testnet'
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
  BGT?: {
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
    if (!chainId) return 'mainnet'
    // You can add more chain ID checks here if needed
    if (chainId === 80069) return 'testnet'
    
    return 'mainnet'
  }

  const networkKey = getNetworkKey()
  const networkContracts = contracts.networks[networkKey]?.contracts as ContractAddresses
  const berachainNetworkContracts = berachainContracts.networks[networkKey]?.contracts as ContractAddresses

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
    bgt: berachainNetworkContracts?.BGT?.address,
    controllers: networkContracts.controllers
  }
} 