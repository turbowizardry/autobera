// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IControllerRegistry {
  function hasPermission(address controller, bytes32 permission) external view returns (bool);
}