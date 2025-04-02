// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IWallet.sol";

contract WalletFactory is Ownable {
    address public immutable implementation;
    address public controllerRegistry;

    event WalletDeployed(address indexed wallet, address indexed owner);
    event ControllerRegistryUpdated(address indexed newRegistry);

    constructor(address _implementation, address _controllerRegistry) Ownable(msg.sender) {
        implementation = _implementation;
        controllerRegistry = _controllerRegistry;
    }

    function createWallet(address owner) external returns (address) {
        address clone = Clones.clone(implementation);
        IWallet(clone).initialize(owner, controllerRegistry);
        emit WalletDeployed(clone, owner);
        return clone;
    }
}