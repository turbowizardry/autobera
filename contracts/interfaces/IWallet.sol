// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IWallet {
    function initialize(address _owner, address _controllerRegistry) external;
    function executeWithPermission(address target, bytes calldata data, bytes32 permission) external;
}
