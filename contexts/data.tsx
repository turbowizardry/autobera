'use client';

import { createContext, useContext, useState, useEffect } from 'react';
import { useAccount, useReadContract, useChainId } from 'wagmi';
import { useContracts } from '@/hooks/useContracts';
import { useVaults } from '@/hooks/useVaults';

import { Vault } from '@/types/vault';

import WALLET_FACTORY_ABI from '@/abi/WalletFactory.json';

interface DataContextType {
  userAddress: string | undefined;
  walletAddress: string | undefined;
  hasWallet: boolean;
  contracts: any;
  vaults: Vault[];
  isVaultsLoading: boolean;
  refetch: () => void;
}

const DataContext = createContext<DataContextType | null>(null);

export function DataProvider({ children }: { children: React.ReactNode }) {
  const { address: userAddress } = useAccount();
  const chainId = useChainId();
  const contracts = useContracts();
  
  const [walletAddress, setWalletAddress] = useState<string | undefined>(undefined);
  const [hasWallet, setHasWallet] = useState(false);
  const [refetchTrigger, setRefetchTrigger] = useState(0);

  const { data, refetch } = useReadContract({
    address: contracts?.walletFactory as `0x${string}`,
    abi: WALLET_FACTORY_ABI.abi,
    functionName: 'getWalletByOwner',
    args: [userAddress!],
    query: {
      enabled: !!userAddress && !!contracts?.walletFactory,
      refetchOnMount: true,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true
    }
  });

  const { vaults, isVaultsLoading } = useVaults(userAddress, chainId, walletAddress, refetchTrigger);

  useEffect(() => {
    if (data) {
      setWalletAddress(data as string);
      setHasWallet(data !== '0x0000000000000000000000000000000000000000');
    } else {
      setWalletAddress(undefined);
      setHasWallet(false);
    }
  }, [data, chainId]);

  useEffect(() => {
    if (userAddress && contracts?.walletFactory) {
      refetch();
    }
  }, [chainId, userAddress, contracts?.walletFactory, refetch]);

  const handleRefetch = () => {
    setRefetchTrigger(prev => prev + 1);
  };

  return (
    <DataContext.Provider value={{ userAddress, walletAddress, hasWallet, contracts, vaults, isVaultsLoading, refetch: handleRefetch }}>
      {children}
    </DataContext.Provider>
  );
}

export function useData() {
  const context = useContext(DataContext);
  if (!context) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
} 