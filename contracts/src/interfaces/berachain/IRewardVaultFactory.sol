// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardVaultFactory {
    function getRewardVault(address lpToken) external view returns (address);
}