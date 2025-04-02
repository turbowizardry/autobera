// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ControllerRegistry is Ownable {
  struct ControllerInfo {
    address controller;
    string name;           // e.g., "Claim BGT"
    bytes32 permissionKey;  // e.g., "CLAIM_BGT"
    string version;        // e.g., "v1.0.1"
    string description;
    bool isActive;
  }

  // permissionKey => list of controllers
  mapping(string => ControllerInfo[]) public controllersByPermission;

  event ControllerRegistered(address controller, string permissionKey, string version);
  event ControllerDeactivated(address controller, string permissionKey);

  constructor() Ownable(msg.sender) {}

  function registerController(
    address controller,
    string calldata permissionKey,
    string calldata name,
    string calldata version,
    string calldata description
  ) external onlyOwner {
    controllersByPermission[permissionKey].push(ControllerInfo({
      controller: controller,
      name: name,
      permissionKey: keccak256(abi.encodePacked(permissionKey)),
      version: version,
      description: description,
      isActive: true
    }));

    emit ControllerRegistered(controller, permissionKey, version);
  }

  function deactivateController(string calldata permissionKey, uint index) external onlyOwner {
    ControllerInfo storage info = controllersByPermission[permissionKey][index];
    info.isActive = false;
    emit ControllerDeactivated(info.controller, permissionKey);
  }

  function getControllers(string calldata permissionKey) external view returns (ControllerInfo[] memory) {
    return controllersByPermission[permissionKey];
  }

  function hasPermission(address controller, bytes32 permissionKey) external view returns (bool) {
    ControllerInfo[] storage controllers = controllersByPermission[bytes32ToString(permissionKey)];
    for (uint i = 0; i < controllers.length; i++) {
        if (controllers[i].controller == controller && controllers[i].isActive) {
            return true;
        }
    }
    return false;
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    bytes memory bytesArray = new bytes(32);
    for (uint256 i = 0; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function getPermissionKey(string calldata permissionKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(permissionKey));
  }
}
