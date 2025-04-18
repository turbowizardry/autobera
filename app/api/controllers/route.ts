import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getSDK } from '@/lib/thirdweb';
import CONTROLLER_REGISTRY_ABI from '@/abi/ControllerRegistry.json';
import WALLET_PERMISSIONS_ABI from '@/abi/WalletPermissions.json';
import { keccak256, toBytes } from 'viem';

const PERMISSION_KEYS = [
  {
    key: "AUTO_CLAIM_BGT_V1",
    name: "Auto-claim BGT",
    description: "Controller for auto claiming BGT rewards from reward vaults",
    hash: keccak256(toBytes("AUTO_CLAIM_BGT_V1")) as `0x${string}`
  }
];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const network = (searchParams.get('network') || 'mainnet') as 'mainnet' | 'testnet';
  const walletAddress = searchParams.get('walletAddress');

  if (!walletAddress) {
    return NextResponse.json(
      { error: 'Wallet address is required' },
      { status: 400 }
    );
  }

  try {
    const sdk = getSDK(network);
    const controllers = await prisma.controller.findMany({
      where: { network },
      include: {
        permissions: {
          where: { walletAddress: walletAddress.toLowerCase() }
        }
      }
    });

    // Fetch current permissions from blockchain
    const updatedControllers = await Promise.all(
      controllers.map(async (controller) => {
        try {
          const permissionKey = PERMISSION_KEYS.find(pk => pk.key === controller.permissionKey)?.hash;
          if (!permissionKey) return controller;

          const contract = await sdk.getContract(controller.address, WALLET_PERMISSIONS_ABI);
          const permission = await contract.call("getPermission", [
            walletAddress,
            controller.address,
            permissionKey
          ]);

          // Update database with latest permission status
          await prisma.walletPermission.upsert({
            where: {
              walletAddress_controllerId: {
                walletAddress: walletAddress.toLowerCase(),
                controllerId: controller.id
              }
            },
            update: {
              isApproved: permission.isApproved,
              approvedAt: permission.approvedAt ? new Date(Number(permission.approvedAt) * 1000) : null,
              lastUpdated: new Date()
            },
            create: {
              walletAddress: walletAddress.toLowerCase(),
              controllerId: controller.id,
              isApproved: permission.isApproved,
              approvedAt: permission.approvedAt ? new Date(Number(permission.approvedAt) * 1000) : null
            }
          });

          return {
            ...controller,
            isApproved: permission.isApproved,
            approvedAt: permission.approvedAt
          };
        } catch (error) {
          console.error(`Error fetching permission for controller ${controller.address}:`, error);
          return controller;
        }
      })
    );

    return NextResponse.json({ controllers: updatedControllers });
  } catch (error) {
    console.error('Error fetching controller permissions:', error);
    return NextResponse.json(
      { error: 'Failed to fetch controller permissions' },
      { status: 500 }
    );
  }
} 