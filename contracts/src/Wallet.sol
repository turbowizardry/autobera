// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./callback/TokenCallback.sol";
import "./interfaces/IControllerRegistry.sol";

contract Wallet is TokenCallbackHandler {
  address public owner;

  IControllerRegistry public controllerRegistry;

  bool public initialized;

  event WalletOperation(address indexed target, bytes4 indexed selector, address indexed wallet, uint256 value);

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyController(bytes32 permission) {
    require(controllerRegistry.hasPermission(msg.sender, permission), "Permission denied");
    _;
  }

  modifier onlyOnce() {
    require(!initialized, "Already initialized");
    _;
    initialized = true;
  }

  function initialize(address _owner, address _controllerRegistry) external onlyOnce {
    require(_owner != address(0), "Invalid owner");
    require(_controllerRegistry != address(0), "Invalid controller registry");
    owner = _owner;
    controllerRegistry = IControllerRegistry(_controllerRegistry);
  }

  function ownerExecute(address target, uint256 value, bytes calldata data) external onlyOwner {
    require(target != address(0), "Zero target address");
    (bool success, ) = target.call{value: value}(data);
    require(success, "Call failed");
  }

  function controllerExecute(address target, uint256 value, bytes calldata data, bytes32 permission) external onlyController(permission) {
    require(target != address(0), "Zero target address");
    (bool success, ) = target.call{value: value}(data);
    require(success, "Permissioned call failed");

    // Extract the function selector from the data
    bytes4 selector;
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, data.offset, 4)
      selector := mload(ptr)
    }
    
    emit WalletOperation(target, selector, msg.sender, value);
  }

  receive() external payable {}
}
