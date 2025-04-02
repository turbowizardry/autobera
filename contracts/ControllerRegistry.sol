// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ControllerRegistry is Ownable {
    struct ControllerInfo {
        address controller;
        string name;           // e.g., "Claim BGT"
        string permissionKey;  // e.g., "CLAIM_BGT"
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
            permissionKey: permissionKey,
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
}
