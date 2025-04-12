'use client';
import { useMemo, useEffect, useRef } from 'react';
import { useData } from '@/contexts/data';
import { Skeleton } from '@/components/ui/skeleton';
import Image from 'next/image';
import { Card } from '@/components/ui/card';
import { CardContent } from '@/components/ui/card';
import { formatUnits } from 'viem';
import { CircleX } from 'lucide-react';
import { CircleCheck } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json';

export function LpTokens() {
  const { userAddress, walletAddress, vaults, isVaultsLoading, refetch: refetchVaults, hasWallet } = useData();
  const hasRefreshedRef = useRef(false);
  
  const { 
    writeContract,
    data: setOperatorHash,
    isPending: isSetOperatorPending 
  } = useWriteContract();

  const { 
    isLoading: isSetOperatorConfirming,
    isSuccess: isSetOperatorConfirmed,
    data: receipt
  } = useWaitForTransactionReceipt({ hash: setOperatorHash });

  useEffect(() => {
    if (isSetOperatorConfirmed && !hasRefreshedRef.current) {
      hasRefreshedRef.current = true;
      refetchVaults();
    }
  }, [isSetOperatorConfirmed, refetchVaults]);

  // Reset the ref when a new transaction starts
  useEffect(() => {
    if (setOperatorHash) {
      hasRefreshedRef.current = false;
    }
  }, [setOperatorHash]);

  // Filter vaults that have a balance
  const vaultsWithBalance = useMemo(() => 
    vaults.filter(vault => (vault.balance || BigInt(0)) > BigInt(0)),
    [vaults]
  );

  // Filter vaults where the user is an operator
  const operatorVaults = useMemo(() => 
    vaultsWithBalance.filter(vault => vault.isOperator),
    [vaultsWithBalance]
  );

  const handleSetOperator = async (vaultAddress: string, operatorAddress: string | null) => {
    if (!hasWallet) {
      console.error("Wallet address not found");
      return;
    }
    try {
      const hash = await writeContract({
        address: vaultAddress as `0x${string}`,
        abi: REWARD_VAULT_ABI,
        functionName: 'setOperator',
        args: [operatorAddress || '0x0000000000000000000000000000000000000000'],
      });
      console.log('Operator transaction sent:', hash);
    } catch (error) {
      console.error("Error setting operator:", error);
    }
  };

  if (isVaultsLoading) {
    return (
      <Card>
        <CardContent>
          <div className="space-y-4">
            <Skeleton className="h-8 w-[200px]" />
            <Skeleton className="h-4 w-[100px]" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!userAddress) {
    return (
      <Card>
        <CardContent>
          <div className="text-center py-4">
            <p className="text-muted-foreground">Please connect your wallet</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (vaultsWithBalance.length === 0) {
    return (
      <Card>
        <CardContent>
          <div className="text-center py-4">
            <p className="text-muted-foreground">No active LP token positions found</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent>
      <h3 className="text-lg font-semibold mb-4">BGT Rewards</h3>
      {vaultsWithBalance.map((vault) => (
        <div 
          key={vault.vaultAddress}
          className="flex items-center justify-between p-4 border rounded-lg"
        >
          <div className="flex items-center space-x-4">
            <Image
              src={vault.logoURI}
              alt={vault.name}
              width={32}
              height={32}
              className="rounded-full"
            />
           <div>
              <h3 className="font-medium">{vault.name}</h3>
              <p className="text-sm text-muted-foreground">
                {parseFloat(formatUnits(vault.balance!, 18)).toFixed(8)} BGT
              </p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            {vault.isOperator && (
              <>
                <CircleCheck className="h-5 w-5 text-green-600" />
                <span className="text-sm text-muted-foreground">
                  Operator
                </span>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => handleSetOperator(vault.vaultAddress, null)}
                  disabled={isSetOperatorPending || isSetOperatorConfirming}
                >
                  {isSetOperatorPending || isSetOperatorConfirming ? 'Removing...' : 'Remove Operator'}
                </Button>
              </>
            )}
            
            {(!vault.isOperator && hasWallet) && (
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => walletAddress && handleSetOperator(vault.vaultAddress, walletAddress)}
                disabled={isSetOperatorPending || isSetOperatorConfirming || !walletAddress}
              >
                {isSetOperatorPending || isSetOperatorConfirming ? 'Setting Operator...' : 'Set Operator'}
              </Button>
            )}
          </div>
        </div>
      ))}
      </CardContent>
    </Card>
  );
}