import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getSDK } from '@/lib/thirdweb';
import { keccak256, toBytes } from 'viem';

const AUTO_CLAIM_PERMISSION = keccak256(toBytes("AUTO_CLAIM_BGT_V1"));

export async function GET(request: Request) {
  // Verify cron secret to ensure only authorized calls
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    // Get all active wallets with auto-claim permissions
    const activePermissions = await prisma.walletPermission.findMany({
      where: {
        isApproved: true,
        controller: {
          permissionKey: "AUTO_CLAIM_BGT_V1",
          isActive: true
        }
      },
      include: {
        controller: true
      }
    });

    const networks: Array<'mainnet' | 'testnet'> = ['mainnet', 'testnet'];
    const results = [];

    for (const network of networks) {
      const sdk = getSDK(network);
      
      // Get all vaults for the network
      const vaults = await prisma.vault.findMany({
        where: { network }
      });

      // Process each wallet's permissions
      for (const permission of activePermissions) {
        try {
          // Check each vault for claimable rewards
          for (const vault of vaults) {
            try {
              const contract = await sdk.getContract(vault.vaultAddress);
              const earned = await contract.call("earned", [permission.walletAddress]);

              // If earned amount is significant enough, trigger claim
              if (earned > BigInt(0)) {
                const controller = await sdk.getContract(permission.controller.address);
                await controller.call("claim", [
                  permission.walletAddress,
                  vault.vaultAddress
                ]);

                results.push({
                  success: true,
                  wallet: permission.walletAddress,
                  vault: vault.vaultAddress,
                  network,
                  earned: earned.toString()
                });
              }
            } catch (error) {
              console.error(
                `Error processing vault ${vault.vaultAddress} for wallet ${permission.walletAddress}:`,
                error
              );
              results.push({
                success: false,
                wallet: permission.walletAddress,
                vault: vault.vaultAddress,
                network,
                error: error.message
              });
            }
          }
        } catch (error) {
          console.error(`Error processing wallet ${permission.walletAddress}:`, error);
          results.push({
            success: false,
            wallet: permission.walletAddress,
            network,
            error: error.message
          });
        }
      }
    }

    return NextResponse.json({ results });
  } catch (error) {
    console.error('Error in claim cron job:', error);
    return NextResponse.json(
      { error: 'Failed to process claims' },
      { status: 500 }
    );
  }
} 