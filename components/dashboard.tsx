'use client';

import WalletBanner from '@/components/walletBanner';


export default function Dashboard() {
  return (
    <div className="sm:mx-auto sm:max-w-7xl">
      <h3 className="text-2xl font-semibold text-white">
        Henlo
      </h3>

      <WalletBanner />
    </div>
  );
}