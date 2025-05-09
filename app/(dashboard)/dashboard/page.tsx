import { WalletBanner } from '@/components/walletBanner'
import { LpTokens } from '@/components/lpTokens'
import { ControllerPermissions } from '@/components/controllerPermissions'

export default function Page() {
  return (
    <>
      <h1 className="text-3xl font-bold tracking-tight text-white">
        Dashboard
      </h1>

      <WalletBanner />
      <LpTokens />
      <ControllerPermissions />
    </>
  )
}
