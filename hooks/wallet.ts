import { useAccount, useReadContract } from 'wagmi'

// Updated ABI to use getWalletByOwner
const WALLET_FACTORY_ABI = [
  {
    inputs: [{ internalType: "address", name: "owner", type: "address" }],
    name: "getWalletByOwner",
    outputs: [
      { internalType: "address", name: "wallet", type: "address" }
    ],
    stateMutability: "view",
    type: "function"
  }
] as const

// ABI for the Wallet contract
const WALLET_ABI = [
  {
    inputs: [],
    name: "controllerRegistry",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function"
  }
] as const

export function useWalletStatus() {
  const { address } = useAccount()
  
  const walletFactoryAddress = '0xE3F95aD9EF9F645dD876598745A28c081EBB3D49'

  // Get the wallet address and existence status for the connected account
  const { data: walletData } = useReadContract({
    address: walletFactoryAddress,
    abi: WALLET_FACTORY_ABI,
    functionName: 'getWalletByOwner',
    args: [address!],
    query: {
      enabled: !!address
    }
  })

  const [walletAddress] = walletData || [undefined, false]
  
  console.log('address', address);
  console.log('walletAddress', walletAddress);


  // Check if the wallet has a controller registry set
  const { data: controllerRegistry } = useReadContract({
    address: walletAddress as `0x${string}`,
    abi: WALLET_ABI,
    functionName: 'controllerRegistry',
    query: {
      enabled: !!walletAddress
    }
  })

  return {
    hasWallet: !!walletAddress,
    walletAddress,
    hasOperator: !!controllerRegistry && controllerRegistry !== '0x0000000000000000000000000000000000000000'
  }
}
