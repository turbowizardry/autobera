// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IWallet.sol";

contract ClaimController {
    bytes32 constant PERMISSION_CLAIM_INCENTIVES = keccak256("CLAIM_INCENTIVES");

    function claimIncentives(address wallet, address incentivesContract, bytes calldata claimData) external {
        IWallet(wallet).controllerExecute(incentivesContract, 0, claimData, PERMISSION_CLAIM_INCENTIVES);
    }
}