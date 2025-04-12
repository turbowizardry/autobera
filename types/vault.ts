export interface Vault {
  stakingTokenAddress: string
  vaultAddress: string
  name: string
  protocol: string
  logoURI: string
  balance?: bigint
  isOperator?: boolean
} 