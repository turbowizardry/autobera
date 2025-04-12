'use client';

import { useEffect } from 'react';
import { useData } from '@/contexts/data';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatUnits } from 'viem';

import { cn } from '@/lib/utils';

import WALLET_FACTORY_ABI from '@/abi/WalletFactory.json';
import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json';

import {
  Circle,
  CircleCheck,
} from 'lucide-react';

export function WalletBanner() {
  const { userAddress, walletAddress, hasWallet, refetch: refetchWalletStatus, contracts } = useData();
  
  // Step 1: Create Wallet
  const { 
    writeContract: writeCreateWallet,
    data: createWalletHash,
    isPending: isCreateWalletPending 
  } = useWriteContract();

  const { 
    isLoading: isCreateWalletConfirming,
    isSuccess: isCreateWalletConfirmed 
  } = useWaitForTransactionReceipt({ hash: createWalletHash });

  useEffect(() => {
    if (isCreateWalletConfirmed) {
      refetchWalletStatus();
    }
  }, [isCreateWalletConfirmed, refetchWalletStatus]);

  const createWallet = async () => {
    try {
      if (!contracts?.walletFactory) {
        console.error("Wallet factory address not found");
        return;
      }
      
      writeCreateWallet({
        address: contracts.walletFactory as `0x${string}`,
        abi: WALLET_FACTORY_ABI.abi,
        functionName: 'createWallet',
        args: []
      });
    } catch (error) {
      console.error("Error creating wallet:", error);
    }
  };

  return (
    <Card>
      <CardContent className="flex flex-row gap-4 justify-between items-center">
        <div className="space-y-2">
          <CardTitle>
            {hasWallet ? 'Your wallet' : 'Create your wallet'}
          </CardTitle>
          <CardDescription>
            {hasWallet ? `Wallet address: ${walletAddress}` : 'Make sure your connected wallet is the wallet holding your LP tokens.'}
          </CardDescription>
        </div>
        {!hasWallet ? (
          <Button onClick={createWallet}>
            Create Wallet
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}