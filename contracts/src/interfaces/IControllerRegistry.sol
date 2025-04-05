// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IControllerRegistry {
  function registerController(address controller, bytes32 permissionKey, string calldata name, string calldata version, string calldata description) external;
  function deactivateController(bytes32 permissionKey, uint index) external;
  function hasPermission(address controller, bytes32 permission) external view returns (bool);
}