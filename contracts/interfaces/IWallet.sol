// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IWallet {
  function initialize(address _owner, address _controllerRegistry) external;
  function ownerExecute(address target, uint256 value, bytes calldata data) external;
  function controllerExecute(address target, uint256 value, bytes calldata data, bytes32 permission) external;
}
