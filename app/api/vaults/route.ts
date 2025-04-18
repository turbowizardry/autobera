import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getSDK } from '@/lib/thirdweb';
import REWARD_VAULT_ABI from '@/abi/berachain/RewardVault.json';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const network = (searchParams.get('network') || 'mainnet') as 'mainnet' | 'testnet';
  const userAddress = searchParams.get('userAddress');
  const walletAddress = searchParams.get('walletAddress');

  try {
    // Get vaults from database
    const vaults = await prisma.vault.findMany({
      where: { network },
      include: {
        operators: true,
      },
    });

    // If user address is provided, fetch earned amounts
    if (userAddress) {
      const sdk = getSDK(network);
      
      // Fetch earned amounts in parallel
      const vaultsWithEarned = await Promise.all(
        vaults.map(async (vault) => {
          try {
            const contract = await sdk.getContract(vault.vaultAddress, REWARD_VAULT_ABI);
            const earned = await contract.call("earned", [userAddress]);
            
            return {
              ...vault,
              earned: earned.toString(),
              isOperator: vault.operators.some(op => 
                op.operator.toLowerCase() === walletAddress?.toLowerCase() && 
                op.isActive
              ),
            };
          } catch (error) {
            console.error(`Error fetching earned for vault ${vault.vaultAddress}:`, error);
            return {
              ...vault,
              earned: "0",
              isOperator: false,
            };
          }
        })
      );

      return NextResponse.json({ vaults: vaultsWithEarned });
    }

    return NextResponse.json({ vaults });
  } catch (error) {
    console.error('Error fetching vaults:', error);
    return NextResponse.json(
      { error: 'Failed to fetch vaults' },
      { status: 500 }
    );
  }
} 