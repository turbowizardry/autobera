'use client';
import { useMemo, useEffect, useRef } from 'react';
import { useData } from '@/contexts/data';
import { Skeleton } from '@/components/ui/skeleton';
import { Card } from '@/components/ui/card';
import { CardContent } from '@/components/ui/card';
import { CircleX } from 'lucide-react';
import { CircleCheck } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import WALLET_PERMISSIONS_ABI from '@/abi/WalletPermissions.json';
import { useControllerPermissions } from '@/hooks/useControllerPermissions';
import { useContracts } from '@/hooks/useContracts';
import { keccak256, toBytes } from 'viem';

export function ControllerPermissions() {
  const { walletAddress, hasWallet } = useData();
  const contracts = useContracts();
  const hasRefreshedRef = useRef(false);
  
  const { 
    controllersByPermission,
    isLoading,
    refetch
  } = useControllerPermissions(
    walletAddress,
    contracts?.controllerRegistry,
    contracts?.walletPermissions
  );
  
  const { 
    writeContract,
    data: setPermissionHash,
    isPending: isSetPermissionPending,
    reset
  } = useWriteContract();

  const { 
    isLoading: isSetPermissionConfirming,
    isSuccess: isSetPermissionConfirmed 
  } = useWaitForTransactionReceipt({ hash: setPermissionHash });

  useEffect(() => {
    if (isSetPermissionConfirmed && !hasRefreshedRef.current) {
      hasRefreshedRef.current = true;
      refetch();
    }
  }, [isSetPermissionConfirmed, refetch]);

  // Reset the ref when a new transaction starts
  useEffect(() => {
    if (setPermissionHash) {
      hasRefreshedRef.current = false;
    }
  }, [setPermissionHash]);

  const handleApprovePermission = async (controller: string, permissionKey: string) => {
    console.log("Approving permission:", controller, permissionKey);
    if (!hasWallet || !walletAddress) {
      console.error("Wallet address not found");
      return;
    }
    try {
      await writeContract({
        address: contracts?.walletPermissions as `0x${string}`,
        abi: WALLET_PERMISSIONS_ABI.abi,
        functionName: 'approvePermission',
        args: [walletAddress, controller, permissionKey],
      });
    } catch (error) {
      console.error("Error approving permission:", error);
      reset();
    }
  };

  const handleRevokePermission = async (controller: string, permissionKey: string) => {
    console.log("Revoking permission:", controller, permissionKey);
    if (!hasWallet || !walletAddress) {
      console.error("Wallet address not found");
      return;
    }
    try {
      await writeContract({
        address: contracts?.walletPermissions as `0x${string}`,
        abi: WALLET_PERMISSIONS_ABI.abi,
        functionName: 'revokePermission',
        args: [walletAddress, controller, permissionKey],
      });
    } catch (error) {
      console.error("Error revoking permission:", error);
      reset();
    }
  };

  if (isLoading) {
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

  if (!walletAddress) {
    return (
      <Card>
        <CardContent>
          <div className="text-center py-4">
            <p className="text-muted-foreground">Please create your wallet first</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (Object.keys(controllersByPermission).length === 0) {
    return (
      <Card>
        <CardContent>
          <div className="text-center py-4">
            <p className="text-muted-foreground">No controllers found</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent>
        <h3 className="text-lg font-semibold mb-4">Wallet Permissions</h3>
        <div className="space-y-4">
          {Object.entries(controllersByPermission).map(([permissionKey, controllers]) => (
            <div key={permissionKey}>
              <div className="space-y-4">
                {controllers.map((controller) => (
                  <div 
                    key={controller.controller}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div>
                      <h4 className="font-medium">{controller.name}</h4>
                      <p className="text-sm text-muted-foreground">
                        {controller.description}
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      {controller.isApproved && (
                        <>
                          <CircleCheck className="h-5 w-5 text-green-600" />
                          <span className="text-sm text-muted-foreground">
                            Approved
                          </span>
                        </>
                      )}
                      
                      {hasWallet && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => controller.isApproved 
                            ? handleRevokePermission(controller.controller, permissionKey)
                            : handleApprovePermission(controller.controller, permissionKey)
                          }
                          disabled={isSetPermissionPending || isSetPermissionConfirming}
                        >
                          {isSetPermissionPending || isSetPermissionConfirming 
                            ? 'Updating...' 
                            : controller.isApproved 
                              ? 'Revoke' 
                              : 'Approve'}
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
} 