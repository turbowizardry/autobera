'use client';
import { useMemo } from 'react';
import { useData } from '@/contexts/data';
import { Skeleton } from '@/components/ui/skeleton';
import Image from 'next/image';

export function LpTokens() {
  const { userAddress,walletAddress, vaults, isVaultsLoading } = useData();

  
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

  if (isVaultsLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-[200px]" />
        <Skeleton className="h-4 w-[100px]" />
      </div>
    );
  }

  if (!userAddress) {
    return (
      <div className="text-center py-4">
        <p className="text-muted-foreground">Please connect your wallet</p>
      </div>
    );
  }

  if (vaultsWithBalance.length === 0) {
    return (
      <div className="text-center py-4">
        <p className="text-muted-foreground">No active LP token positions found</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
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
              <p className="text-sm text-muted-foreground">{vault.protocol}</p>
            </div>
          </div>
          <div className="text-right">
            <p className="font-medium">{vault.balance?.toString()}</p>
            {vault.isOperator && (
              <p className="text-sm text-green-500">Operator</p>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}