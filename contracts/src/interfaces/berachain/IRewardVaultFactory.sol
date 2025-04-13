// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardVaultFactory {
    /**
     * @notice Gets the vault for the given staking token.
     * @param stakingToken The address of the staking token.
     * @return The address of the vault.
     */
    function getVault(address stakingToken) external view returns (address);
}