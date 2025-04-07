import { useAccount, useReadContract } from 'wagmi'

import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json'
import WALLET_FACTORY_ABI from '@/abi/WalletFactory.json'

import { RewardVaultFactoryAddress, WalletFactoryAddress } from '@/lib/contracts'


export function useWalletStatus() {
  const { address: userAddress } = useAccount()
  
  const rewardVaultAddress = '0x9C84a17467d0F691b4a6FE6c64fA00eDb55D9646';

  const { data: walletAddress, refetch: refetchWallet } = useReadContract({
    address: WalletFactoryAddress as `0x${string}`,
    abi: WALLET_FACTORY_ABI,
    functionName: 'getWalletByOwner',
    args: [userAddress!],
    query: {
      enabled: !!userAddress
    }
  })

  const { data: operator, refetch: refetchOperator } = useReadContract({
    address: rewardVaultAddress as `0x${string}`,
    abi: REWARD_VAULT_ABI,
    functionName: 'operator',
    args: [userAddress],
    query: {
      enabled: !!userAddress
    }
  })

  const { data: userBalance, refetch: refetchBalance } = useReadContract({
    address: rewardVaultAddress,
    abi: REWARD_VAULT_ABI,
    functionName: 'balanceOf',
    args: [userAddress],
    query: {
      enabled: !!userAddress,
      select: (data) => BigInt(data as number)
    }
  })

  const refetch = async () => {
    await Promise.all([
      refetchWallet(),
      refetchOperator(),
      refetchBalance()
    ]);
  };

  const result = {
    hasWallet: walletAddress !== undefined,
    walletAddress,
    hasOperator: !!operator,
    userBalance,
    refetch
  }

  console.log('result', result);
  
  return result;
}
