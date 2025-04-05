'use client'

import { useAccount } from 'wagmi';

import Hero from './hero';
import Onboarding from './onboarding';

export default function ContentSelect() {
  const { isConnected } = useAccount();

  return (
    <>
      {isConnected ? <Onboarding /> : <Hero />}
    </>
  )
}
