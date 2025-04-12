import { useMemo, useState, useEffect } from 'react'
import { useReadContract } from 'wagmi'
import { usePublicClient } from 'wagmi'

import MainnetVaults from '@/data/vaults.json';
import TestnetVaults from '@/data/testnetVaults.json';
import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json';

interface Vault {
  vaultAddress: string
  name: string
  protocol: string
  logoURI: string
  balance?: bigint
  isOperator?: boolean
}

export function useVaults(userAddress?: string, chainId?: number) {
  const [vaultBalances, setVaultBalances] = useState<Record<string, bigint | undefined>>({});
  const [isLoading, setIsLoading] = useState(false);
  const publicClient = usePublicClient();

  const vaults = useMemo(() => {
    return chainId ? (chainId === 80069 ? TestnetVaults.vaults : MainnetVaults.vaults) : [];
  }, [chainId]);

  useEffect(() => {
    const fetchBalances = async () => {
      if (!userAddress || !chainId || vaults.length === 0 || !publicClient) {
        setVaultBalances({});
        return;
      }

      setIsLoading(true);
      try {
        const balancePromises = vaults.map(async (vault) => {
          try {
            const balance = await publicClient.readContract({
              address: vault.vaultAddress as `0x${string}`,
              abi: REWARD_VAULT_ABI,
              functionName: 'balanceOf',
              args: [userAddress]
            });
            return { vaultAddress: vault.vaultAddress, balance: balance as bigint };
          } catch (error) {
            console.error(`Error fetching balance for vault ${vault.vaultAddress}:`, error);
            return { vaultAddress: vault.vaultAddress, balance: undefined };
          }
        });

        const results = await Promise.all(balancePromises);
        const newBalances = results.reduce((acc, { vaultAddress, balance }) => {
          acc[vaultAddress] = balance;
          return acc;
        }, {} as Record<string, bigint | undefined>);

        setVaultBalances(newBalances);
      } catch (error) {
        console.error('Error fetching vault balances:', error);
        setVaultBalances({});
      } finally {
        setIsLoading(false);
      }
    };

    fetchBalances();
  }, [userAddress, chainId, vaults, publicClient]);

  const vaultsWithBalances = useMemo(() => {
    return vaults.map((vault) => ({
      ...vault,
      balance: vaultBalances[vault.vaultAddress]
    }));
  }, [vaults, vaultBalances]);

  return {
    vaults: vaultsWithBalances,
    isVaultsLoading: isLoading || vaultsWithBalances.some(vault => vault.balance === undefined)
  }
} 