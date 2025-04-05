// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IWallet.sol";

contract WalletFactory is Ownable {
  address public immutable implementation;
  address public controllerRegistry;

  // Add storage for wallet tracking
  mapping(address => address) public ownerToWallet;
  address[] public allWallets;

  mapping(address => mapping(bytes32 => bool)) public controllerPermissions;

  event WalletDeployed(address indexed wallet, address indexed owner);
  event ControllerRegistryUpdated(address indexed newRegistry);
  event PermissionUpdated(address indexed controller, bytes32 indexed permission, bool allowed);

  constructor(address _implementation, address _controllerRegistry) Ownable(msg.sender) {
    implementation = _implementation;
    controllerRegistry = _controllerRegistry;
  }

  function createWallet() external returns (address) {
    require(ownerToWallet[msg.sender] == address(0), "Wallet already exists for this owner");
    
    address clone = Clones.clone(implementation);
    IWallet(clone).initialize(msg.sender, controllerRegistry);
    
    // Store wallet information
    ownerToWallet[msg.sender] = clone;
    allWallets.push(clone);
    
    emit WalletDeployed(clone, msg.sender);
    return clone;
  }

  function setControllerPermission(address controller, bytes32 permission, bool allowed) external onlyOwner {
    controllerPermissions[controller][permission] = allowed;
    emit PermissionUpdated(controller, permission, allowed);
  }

  // New functions to query wallet information
  function getWalletByOwner(address owner) external view returns (address) {
    return ownerToWallet[owner];
  }

  function getAllWallets() external view returns (address[] memory) {
    return allWallets;
  }

  function getWalletsCount() external view returns (uint256) {
    return allWallets.length;
  }
}