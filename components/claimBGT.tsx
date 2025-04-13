import { useEffect } from 'react';
import { useData } from '@/contexts/data';
import { Button } from '@/components/ui/button';
import { Vault } from '@/types/vault';

import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import CLAIM_BGT_ABI from '@/abi/controllers/ClaimBGTController.json';

interface ClaimBGTProps {
  vault: Vault;
}

export function ClaimBGT({ vault }: ClaimBGTProps) {
  const { contracts, walletAddress } = useData();

  const { 
    writeContract: writeClaimBGT,
    data: claimBGTHash,
    isPending: isClaimBGTPending 
  } = useWriteContract();

  const { 
    isLoading: isClaimBGTConfirming,
    isSuccess: isClaimBGTConfirmed 
  } = useWaitForTransactionReceipt({ hash: claimBGTHash });

  const handleClaim = async () => {
    try {
      if (!contracts?.controllers?.ClaimBGTController?.address || !walletAddress) {
        console.error("ClaimBGT controller address or wallet address not found");
        return;
      }

      writeClaimBGT({
        address: contracts.controllers.ClaimBGTController.address as `0x${string}`,
        abi: CLAIM_BGT_ABI.abi,
        functionName: 'claimRewards',
        args: [walletAddress, vault.stakingTokenAddress]
      });
    } catch (error) {
      console.error("Error claiming BGT:", error);
    }
  };

  useEffect(() => {
    if (isClaimBGTConfirmed) {
      console.log("ClaimBGT confirmed");
    }
  }, [isClaimBGTConfirmed]);

  return (
    <Button 
      onClick={handleClaim}
      disabled={isClaimBGTPending || isClaimBGTConfirming || !vault.isOperator}
      size="sm"
      variant="outline"
    >
      {isClaimBGTPending || isClaimBGTConfirming ? 'Claiming...' : 'Claim BGT'}
    </Button>
  );
} 