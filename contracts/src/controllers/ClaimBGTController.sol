// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseController.sol";
import "../interfaces/IWallet.sol";
import "../interfaces/berachain/IRewardVault.sol";
import "../interfaces/berachain/IRewardVaultFactory.sol";

contract ClaimBGTController is BaseController {
    event RewardClaimed(address indexed wallet, address indexed lpToken, uint256 amount);
    
    constructor(address _rewardVaultFactory) BaseController(_rewardVaultFactory) Ownable(msg.sender) {
        permission = keccak256("AUTO_CLAIM_BGT_V1");
        name = "Auto-claim BGT";
        description = "Controller for auto claiming BGT rewards from reward vaults";
    }
    /**
     * @dev Claims BGT rewards for a given wallet and LP token
     * @param wallet The address of the wallet to claim rewards for
     * @param lpToken The address of the LP token to claim rewards from
     */
    function claimRewards(address wallet, address lpToken) external {
        // Get the reward vault for this LP token
        address rewardVault = IRewardVaultFactory(rewardVaultFactory).getVault(lpToken);
        require(rewardVault != address(0), "No reward vault found for LP token");

        // Get the wallet owner
        address owner = IWallet(payable(wallet)).owner();

        // Build calldata for getReward function
        bytes memory data = abi.encodeWithSelector(IRewardVault.getReward.selector, owner, payable(wallet));

        // Call wallet's controllerExecute
        IWallet(payable(wallet)).controllerExecute(
            rewardVault,  // target
            0,           // value
            data,        // calldata
            permission   // permission
        );

        emit RewardClaimed(wallet, lpToken, 0); // Amount is not available in the current interface
    }
}