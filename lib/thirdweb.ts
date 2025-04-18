import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import { BeraChain, BeraChainTestnet } from "@thirdweb-dev/chains";

const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY;

if (!PRIVATE_KEY) {
  throw new Error("No private key found");
}

export const getSDK = (network: 'mainnet' | 'testnet') => {
  return ThirdwebSDK.fromPrivateKey(
    PRIVATE_KEY,
    network === 'mainnet' ? BeraChain : BeraChainTestnet
  );
}; 