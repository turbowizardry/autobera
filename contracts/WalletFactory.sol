// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IWallet.sol";

contract WalletFactory is Ownable {
    address public immutable implementation;
    address public controllerRegistry;

    mapping(address => mapping(bytes32 => bool)) public controllerPermissions;

    event WalletDeployed(address indexed wallet, address indexed owner);
    event ControllerRegistryUpdated(address indexed newRegistry);
    event PermissionUpdated(address indexed controller, bytes32 indexed permission, bool allowed);

    constructor(address _implementation, address _controllerRegistry) Ownable(msg.sender) {
        implementation = _implementation;
        controllerRegistry = _controllerRegistry;
    }

    function createWallet() external returns (address) {
        address clone = Clones.clone(implementation);
        IWallet(clone).initialize(msg.sender, controllerRegistry);
        emit WalletDeployed(clone, msg.sender);
        return clone;
    }

    function setControllerPermission(address controller, bytes32 permission, bool allowed) external onlyOwner {
        controllerPermissions[controller][permission] = allowed;
        emit PermissionUpdated(controller, permission, allowed);
    }
}