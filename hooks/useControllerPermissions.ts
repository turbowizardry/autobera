import { useMemo, useState, useEffect } from 'react'
import { usePublicClient } from 'wagmi'
import CONTROLLER_REGISTRY_ABI from '@/abi/ControllerRegistry.json'
import WALLET_PERMISSIONS_ABI from '@/abi/WalletPermissions.json'
import { keccak256, toBytes } from 'viem'

interface ControllerInfo {
  controller: string
  name: string
  permissionKey: string
  description: string
  isActive: boolean
  isApproved?: boolean
  approvedAt?: bigint
}

interface Permission {
  permissionKey: string
  controller: string
  isApproved: boolean
  approvedAt: bigint
}

const permissionKeys = [
  {
    key: "AUTO_CLAIM_BGT_V1",
    name: "Auto-claim BGT",
    description: "Controller for auto claiming BGT rewards from reward vaults",
    hash: keccak256(toBytes("AUTO_CLAIM_BGT_V1")) as `0x${string}`
  }
]

export function useControllerPermissions(
  walletAddress?: string,
  controllerRegistryAddress?: string,
  walletPermissionsAddress?: string
) {
  const [controllers, setControllers] = useState<Record<string, ControllerInfo[]>>({})
  const [isLoading, setIsLoading] = useState(false)
  const publicClient = usePublicClient()

  const fetchData = async () => {
    if (!walletAddress || !controllerRegistryAddress || !walletPermissionsAddress || !publicClient) {
      setControllers({})
      return
    }

    setIsLoading(true)
    try {
      // For each permission key, get its controllers
      const controllerPromises = permissionKeys.map(async (permissionKey) => {
        try {
          const controllers = await publicClient.readContract({
            address: controllerRegistryAddress as `0x${string}`,
            abi: CONTROLLER_REGISTRY_ABI.abi,
            functionName: 'getControllers',
            args: [permissionKey.hash]
          }) as ControllerInfo[]

          // For each controller, fetch its permission status
          if(!controllers) {
            return { permissionKey: permissionKey.hash, controllers: [] }
          }
          
          const controllersWithPermissions = await Promise.all(
            controllers.map(async (controller) => {
              try {
                const permission = await publicClient.readContract({
                  address: walletPermissionsAddress as `0x${string}`,
                  abi: WALLET_PERMISSIONS_ABI.abi,
                  functionName: 'getPermission',
                  args: [walletAddress, controller.controller, permissionKey.hash]
                }) as Permission

                return {
                  ...controller,
                  isApproved: permission.isApproved,
                  approvedAt: permission.approvedAt
                }
              } catch (error) {
                console.error(`Error fetching permission for controller ${controller.controller}:`, error)
                return {
                  ...controller,
                  isApproved: false,
                  approvedAt: BigInt(0)
                }
              }
            })
          )

          return { permissionKey: permissionKey.hash, controllers: controllersWithPermissions }
        } catch (error) {
          console.error(`Error fetching controllers for permission key ${permissionKey.hash}:`, error)
          return { permissionKey: permissionKey.hash, controllers: [] }
        }
      })

      const controllerResults = await Promise.all(controllerPromises)
      const newControllers = controllerResults.reduce((acc, { permissionKey, controllers }) => {
        acc[permissionKey] = controllers
        return acc
      }, {} as Record<string, ControllerInfo[]>)

      setControllers(newControllers)
    } catch (error) {
      console.error('Error fetching controller permissions:', error)
      setControllers({})
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [walletAddress, controllerRegistryAddress, walletPermissionsAddress, publicClient])

  const controllersByPermission = useMemo(() => {
    return controllers
  }, [controllers])

  const hasPermission = useMemo(() => {
    return (permissionKey: string, controller: string) => {
      const permissionControllers = controllers[permissionKey]
      if (!permissionControllers) return false
      const controllerInfo = permissionControllers.find(c => c.controller === controller)
      return controllerInfo?.isApproved ?? false
    }
  }, [controllers])

  return {
    controllersByPermission,
    isLoading,
    refetch: fetchData
  }
} 