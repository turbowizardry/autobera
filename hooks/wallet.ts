import { useAccount, useReadContract } from 'wagmi'

import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json'
import WALLET_FACTORY_ABI from '@/abi/WalletFactory.json'

import { RewardVaultFactoryAddress, WalletFactoryAddress } from '@/lib/contracts'


export function useWalletStatus() {
  const { address: userAddress } = useAccount()
  
  const { data: walletAddress, refetch: refetchWallet } = useReadContract({
    address: WalletFactoryAddress as `0x${string}`,
    abi: WALLET_FACTORY_ABI,
    functionName: 'getWalletByOwner',
    args: [userAddress!],
    query: {
      enabled: !!userAddress
    }
  })

  const refetch = async () => {
    await Promise.all([
      refetchWallet()
    ]);
  };

  const result = {
    hasWallet: walletAddress !== undefined && walletAddress !== '0x0000000000000000000000000000000000000000',
    walletAddress,
    refetch
  }

  console.log('result', result);
  
  return result;
}
