'use client';
import { useEffect } from 'react';

import { useWalletStatus } from '@/hooks/wallet';
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

const walletFactoryAddress = '0xE3F95aD9EF9F645dD876598745A28c081EBB3D49';
const rewardVaultAddress = '0x9C84a17467d0F691b4a6FE6c64fA00eDb55D9646';


export default function WalletBanner() {
  const { address: userAddress } = useAccount();
  const { walletAddress, hasWallet, refetch: refetchWalletStatus } = useWalletStatus();
  
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
      writeCreateWallet({
        address: walletFactoryAddress,
        abi: WALLET_FACTORY_ABI,
        functionName: 'createWallet',
      })
    } catch (error) {
      console.error("Error creating wallet:", error);
    }
  };

  return (
    <div>
      <Card>
        <CardContent className="flex flex-row gap-4 justify-between">
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
    </div>
  );
}