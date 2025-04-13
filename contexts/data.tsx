'use client';

import { createContext, useContext, useState, useEffect } from 'react';
import { useAccount, useReadContract, useChainId } from 'wagmi';
import { useContracts } from '@/hooks/useContracts';
import { useVaults } from '@/hooks/useVaults';

import { Vault } from '@/types/vault';

import WALLET_FACTORY_ABI from '@/abi/WalletFactory.json';

// Standard ERC20 ABI for balanceOf function
const ERC20_ABI = [
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "type": "function"
  }
] as const;

interface DataContextType {
  userAddress: string | undefined;
  walletAddress: string | undefined;
  hasWallet: boolean;
  contracts: any;
  vaults: Vault[];
  isVaultsLoading: boolean;
  bgtBalance: bigint | undefined;
  refetch: () => void;
}

const DataContext = createContext<DataContextType | null>(null);

export function DataProvider({ children }: { children: React.ReactNode }) {
  const { address: userAddress } = useAccount();
  const chainId = useChainId();
  const contracts = useContracts();
  
  const [walletAddress, setWalletAddress] = useState<string | undefined>(undefined);
  const [hasWallet, setHasWallet] = useState(false);
  const [shouldRefetchVaults, setShouldRefetchVaults] = useState(false);

  const { data: walletData, refetch: refetchWallet } = useReadContract({
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

  const { data: bgtBalance } = useReadContract({
    address: contracts?.bgt as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [walletAddress!],
    query: {
      enabled: !!walletAddress && !!contracts?.bgt,
      refetchOnMount: true,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true
    }
  });

  const { vaults, isVaultsLoading } = useVaults(userAddress, chainId, walletAddress, shouldRefetchVaults);

  useEffect(() => {
    if (walletData) {
      setWalletAddress(walletData as string);
      setHasWallet(walletData !== '0x0000000000000000000000000000000000000000');
    } else {
      setWalletAddress(undefined);
      setHasWallet(false);
    }
  }, [walletData]);

  useEffect(() => {
    if (userAddress && contracts?.walletFactory) {
      refetchWallet();
    }
  }, [userAddress, contracts?.walletFactory]);

  useEffect(() => {
    if (shouldRefetchVaults) {
      setShouldRefetchVaults(false);
    }
  }, [shouldRefetchVaults]);

  const handleRefetch = () => {
    setShouldRefetchVaults(true);
  };

  return (
    <DataContext.Provider value={{ 
      userAddress, 
      walletAddress, 
      hasWallet, 
      contracts, 
      vaults, 
      isVaultsLoading, 
      bgtBalance: bgtBalance as bigint | undefined,
      refetch: handleRefetch 
    }}>
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