// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IWallet.sol";
import "./interfaces/IWalletPermissions.sol";

contract WalletFactory is Ownable {
  address public immutable implementation;
  address public controllerRegistry;
  address public walletPermissions;

  // Add storage for wallet tracking
  mapping(address => address) public ownerToWallet;
  address[] public allWallets;

  mapping(address => mapping(bytes32 => bool)) public controllerPermissions;

  event WalletDeployed(address indexed wallet, address indexed owner);
  event ControllerRegistryUpdated(address indexed newRegistry);
  event WalletPermissionsUpdated(address indexed newPermissions);
  event PermissionUpdated(address indexed controller, bytes32 indexed permission, bool allowed);

  constructor(
    address _implementation,
    address _controllerRegistry,
    address _walletPermissions
  ) Ownable(msg.sender) {
    implementation = _implementation;
    controllerRegistry = _controllerRegistry;
    walletPermissions = _walletPermissions;
  }

  function createWallet() external returns (address) {
    require(ownerToWallet[msg.sender] == address(0), "Wallet already exists for this owner");
    
    address clone = Clones.clone(implementation);
    IWallet(payable(clone)).initialize(
      msg.sender,
      controllerRegistry,
      walletPermissions
    );
    
    // Store wallet information
    ownerToWallet[msg.sender] = clone;
    allWallets.push(clone);
    
    emit WalletDeployed(clone, msg.sender);
    return clone;
  }

  function setControllerRegistry(address _controllerRegistry) external onlyOwner {
    controllerRegistry = _controllerRegistry;
    emit ControllerRegistryUpdated(_controllerRegistry);
  }

  function setWalletPermissions(address _walletPermissions) external onlyOwner {
    walletPermissions = _walletPermissions;
    emit WalletPermissionsUpdated(_walletPermissions);
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