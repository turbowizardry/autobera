'use client';
import { useEffect } from 'react';

import { useWalletStatus } from '@/hooks/useWallet';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
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

type Action = {
  text: string;
  onClick: () => void;
  isPending: boolean;
  isConfirming: boolean;
}

const step = (
  title: string, 
  description: string, 
  actions: Action[],
  isActive: boolean, 
  isDone: boolean
) => {
  return (
    <li className={cn("relative p-4 rounded-lg", isActive && "bg-gray-800")}>
      <div className="flex items-start">
        {isDone ? (
          <CircleCheck
            className="size-6 shrink-0 text-white"
            aria-hidden={true}
          />
        ) : isActive ? (
          <Circle
            className="size-6 shrink-0 text-white"
            aria-hidden={true}
          />
        ) : (
          <Circle
            className="size-6 shrink-0 text-gray-500"
            aria-hidden={true}
          />
        )}
        <div className="ml-3 w-0 flex-1 pt-0.5">
          <p className="font-bold leading-5 text-white">
            {title}
          </p>
          <p className="mt-1 text-gray-300 leading-6">
            {description}
          </p>
          <div className="mt-4 flex gap-2">
            {actions.map((action, index) => (
              <Button
                key={index}
                onClick={action.onClick}
                variant="default"
                disabled={!isActive || action.isPending || action.isConfirming}
                loading={action.isPending || action.isConfirming}
              >
                {action.text}
              </Button>
            ))}
          </div>
        </div>
      </div>
    </li>
  )
}

export default function Onboarding() {
  const { address: userAddress } = useAccount();
  const { walletAddress, hasWallet, refetch: refetchWalletStatus } = useWalletStatus();
  
  let activeStep = 1;
  if(hasWallet) activeStep = 2;
  if(hasOperator) activeStep = 3;

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

  // Step 2: Set Operator
  const {
    writeContract: writeSetOperator,
    data: setOperatorHash,
    isPending: isSetOperatorPending
  } = useWriteContract();

  const {
    isLoading: isSetOperatorConfirming,
    isSuccess: isSetOperatorConfirmed
  } = useWaitForTransactionReceipt({ hash: setOperatorHash });

  // Step 3: Approve & Claim
  const {
    writeContract: writeApprove,
    data: approveHash,
    isPending: isApprovePending
  } = useWriteContract();

  const {
    isLoading: isApproveConfirming,
    isSuccess: isApproveConfirmed
  } = useWaitForTransactionReceipt({ hash: approveHash });

  const {
    writeContract: writeClaim,
    data: claimHash,
    isPending: isClaimPending
  } = useWriteContract();

  const {
    isLoading: isClaimConfirming,
    isSuccess: isClaimConfirmed
  } = useWaitForTransactionReceipt({ hash: claimHash });

  useEffect(() => {
    if (isCreateWalletConfirmed || isSetOperatorConfirmed || isClaimConfirmed) {
      refetchWalletStatus();
    }
  }, [isCreateWalletConfirmed, isSetOperatorConfirmed, isClaimConfirmed, refetchWalletStatus]);

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

  const setOperator = async () => {
    try {
      writeSetOperator({
        address: rewardVaultAddress,
        abi: REWARD_VAULT_ABI,
        functionName: 'setOperator',
        args: [walletAddress],
      })
    } catch (error) {
      console.error("Error setting operator:", error);
    }
  };

  const approve = async () => {
    try {
      writeApprove({
        address: rewardVaultAddress,
        abi: REWARD_VAULT_ABI,
        functionName: 'approve',
        args: [walletAddress, userBalance],
      })
    } catch (error) {
      console.error("Error approving:", error);
    }
  };

  const claim = async () => {
    try {
      writeClaim({
        address: rewardVaultAddress,
        abi: REWARD_VAULT_ABI,
        functionName: 'claim',
      })
    } catch (error) {
      console.error("Error claiming:", error);
    }
  };

  return (
    <>
      <div className="sm:mx-auto sm:max-w-xl">
        <h3 className="text-2xl font-semibold text-white">
          Henlo, let's get you started
        </h3>
        <p className="text-gray-300 mt-1">
          Complete the steps below to open your AutoBGT wallet
        </p>
        <ul role="list" className="mt-8 space-y-3">
          {step(
            'Create a wallet', 
            isCreateWalletPending || isCreateWalletConfirming
              ? "Creating your wallet..." 
              : "To start using AutoBGT, you need to create a wallet. It's free",
            [{
              text: 'Create wallet',
              onClick: createWallet,
              isPending: isCreateWalletPending,
              isConfirming: isCreateWalletConfirming
            }],
            activeStep === 1, 
            activeStep > 1
          )}
          {step(
            'Assign operator', 
            'Allow your new wallet to collect BGT from your staked LP tokens.',
            [{
              text: 'Assign operator',
              onClick: setOperator,
              isPending: isSetOperatorPending,
              isConfirming: isSetOperatorConfirming
            }],
            activeStep === 2, 
            activeStep > 2
          )}
          {step(
            'Claim your first BGT', 
            `Claim your first BGT to the new wallet to start automation. You have ${userBalance ? Number(formatUnits(userBalance, 18)).toFixed(6) : 0} BGT to claim.`,
            [
              {
                text: 'Approve',
                onClick: approve,
                isPending: isApprovePending,
                isConfirming: isApproveConfirming
              },
              {
                text: 'Claim',
                onClick: claim,
                isPending: isClaimPending,
                isConfirming: isClaimConfirming
              }
            ],
            activeStep === 3, 
            activeStep > 3
          )}
        </ul>
      </div>
    </>
  );
}