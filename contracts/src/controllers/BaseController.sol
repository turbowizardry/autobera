// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseController
 * @dev Base contract for all controllers that need to interact with reward vaults
 */
abstract contract BaseController is Ownable {
    address public rewardVaultFactory;
    bytes32 public permission;
    string public name;
    string public description;

    event RewardVaultFactoryUpdated(address indexed oldFactory, address indexed newFactory);

    constructor(address _rewardVaultFactory) {
        rewardVaultFactory = _rewardVaultFactory;
    }

    /**
     * @dev Updates the reward vault factory address
     * @param _newFactory The new reward vault factory address
     */
    function setRewardVaultFactory(address _newFactory) external onlyOwner {
        require(_newFactory != address(0), "Invalid factory address");
        address oldFactory = rewardVaultFactory;
        rewardVaultFactory = _newFactory;
        emit RewardVaultFactoryUpdated(oldFactory, _newFactory);
    }
} 