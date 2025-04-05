import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  berachain,
  berachainBepolia
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'RainbowKit demo',
  projectId: 'YOUR_PROJECT_ID',
  chains: [
    berachain,
    berachainBepolia,
    ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === 'true' ? [berachainBepolia] : []),
  ],
  ssr: true,
});