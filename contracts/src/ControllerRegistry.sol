// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ControllerRegistry is Ownable {
  struct ControllerInfo {
    address controller;
    string name;           // e.g., "Claim BGT"
    bytes32 permissionKey;  // e.g., "CLAIM_BGT"
    string description;
    bool isActive;
  }

  // permissionKey => list of controllers
  mapping(bytes32 => ControllerInfo[]) public controllersByPermission;

  event ControllerRegistered(address controller, bytes32 permissionKey);
  event ControllerDeactivated(address controller, bytes32 permissionKey);

  constructor() Ownable(msg.sender) {}

  function registerController(
    address controller,
    bytes32 permissionKey,
    string calldata name,
    string calldata description
  ) external onlyOwner {
    require(controller != address(0), "Invalid controller address");
    require(permissionKey != bytes32(0), "Invalid permission key");
    require(controllersByPermission[permissionKey].length == 0, "Permission key already registered");

    controllersByPermission[permissionKey].push(ControllerInfo({
      controller: controller,
      name: name,
      permissionKey: permissionKey,
      description: description,
      isActive: true
    }));

    emit ControllerRegistered(controller, permissionKey);
  }

  function deactivateController(bytes32 permissionKey, uint index) external onlyOwner {
    require(controllersByPermission[permissionKey].length > 0, "Permission key not registered");
    require(index < controllersByPermission[permissionKey].length, "Invalid index");

    ControllerInfo storage info = controllersByPermission[permissionKey][index];
    info.isActive = false;
    emit ControllerDeactivated(info.controller, permissionKey);
  }

  function getControllers(bytes32 permissionKey) external view returns (ControllerInfo[] memory) {
    return controllersByPermission[permissionKey];
  }

  function hasPermission(address controller, bytes32 permissionKey) external view returns (bool) {
    require(controller != address(0), "Invalid controller address");
    require(permissionKey != bytes32(0), "Invalid permission key");
    require(controllersByPermission[permissionKey].length > 0, "Permission key not registered");

    ControllerInfo[] storage controllers = controllersByPermission[permissionKey];

    for (uint i = 0; i < controllers.length; i++) {
      if (controllers[i].controller == controller && controllers[i].isActive) {
        return true;
      }
    }

    return false;
  }
}
