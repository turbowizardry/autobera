'use client'

import { useAccount } from 'wagmi';

import Hero from './hero';
import Dashboard from './dashboard';

export default function ContentSelect() {
  const { isConnected } = useAccount();

  return (
    <>
      {isConnected ? <Dashboard /> : <Hero />}
    </>
  )
}
