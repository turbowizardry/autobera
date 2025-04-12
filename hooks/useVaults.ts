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

export function useVaults(userAddress?: string, chainId?: number, walletAddress?: string, refetchTrigger?: any) {
  const [vaultBalances, setVaultBalances] = useState<Record<string, bigint | undefined>>({});
  const [vaultOperators, setVaultOperators] = useState<Record<string, boolean | undefined>>({});
  const [isLoading, setIsLoading] = useState(false);
  const publicClient = usePublicClient();

  const vaults = useMemo(() => {
    return chainId ? (chainId === 80069 ? TestnetVaults.vaults : MainnetVaults.vaults) : [];
  }, [chainId]);

  useEffect(() => {
    const fetchBalances = async () => {
      if (!userAddress || !chainId || vaults.length === 0 || !publicClient) {
        setVaultBalances({});
        setVaultOperators({});
        return;
      }

      setIsLoading(true);
      try {
        const balancePromises = vaults.map(async (vault) => {
          try {
            const balance = await publicClient.readContract({
              address: vault.vaultAddress as `0x${string}`,
              abi: REWARD_VAULT_ABI,
              functionName: 'earned',
              args: [userAddress]
            });
            return { vaultAddress: vault.vaultAddress, balance: balance as bigint };
          } catch (error) {
            console.error(`Error fetching balance for vault ${vault.vaultAddress}:`, error);
            return { vaultAddress: vault.vaultAddress, balance: undefined };
          }
        });

        const operatorPromises = vaults.map(async (vault) => {
          if (!walletAddress) {
            return { vaultAddress: vault.vaultAddress, isOperator: false };
          }
          try {
            const isOperator = await publicClient.readContract({
              address: vault.vaultAddress as `0x${string}`,
              abi: REWARD_VAULT_ABI,
              functionName: 'operator',
              args: [userAddress]
            });
            const isOperatorAddress = isOperator as `0x${string}` | undefined;
            const isOperatorStatus = isOperatorAddress && 
              isOperatorAddress !== '0x0000000000000000000000000000000000000000' && 
              isOperatorAddress.toLowerCase() === walletAddress.toLowerCase();

            return { vaultAddress: vault.vaultAddress, isOperator: isOperatorStatus as boolean };
          } catch (error) {
            console.error(`Error fetching operator status for vault ${vault.vaultAddress}:`, error);
            return { vaultAddress: vault.vaultAddress, isOperator: false };
          }
        });

        const [balanceResults, operatorResults] = await Promise.all([
          Promise.all(balancePromises),
          Promise.all(operatorPromises)
        ]);

        const newBalances = balanceResults.reduce((acc, { vaultAddress, balance }) => {
          acc[vaultAddress] = balance;
          return acc;
        }, {} as Record<string, bigint | undefined>);

        const newOperators = operatorResults.reduce((acc, { vaultAddress, isOperator }) => {
          acc[vaultAddress] = isOperator;
          return acc;
        }, {} as Record<string, boolean | undefined>);

        setVaultBalances(newBalances);
        setVaultOperators(newOperators);
      } catch (error) {
        console.error('Error fetching vault data:', error);
        setVaultBalances({});
        setVaultOperators({});
      } finally {
        setIsLoading(false);
      }
    };

    fetchBalances();
  }, [userAddress, walletAddress, chainId, vaults, publicClient, refetchTrigger]);

  const vaultsWithBalances = useMemo(() => {
    return vaults.map((vault) => ({
      ...vault,
      balance: vaultBalances[vault.vaultAddress],
      isOperator: vaultOperators[vault.vaultAddress]
    }));
  }, [vaults, vaultBalances, vaultOperators]);

  return {
    vaults: vaultsWithBalances,
    isVaultsLoading: isLoading || vaultsWithBalances.some(vault => vault.balance === undefined || vault.isOperator === undefined)
  }
} 