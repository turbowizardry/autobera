// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletFactory is Ownable {
    address public immutable implementation;
    event WalletDeployed(address indexed wallet, address indexed owner);

    constructor(address _implementation) Ownable(msg.sender) {
        implementation = _implementation;
    }

    function createWallet(address owner) external returns (address) {
        address clone = Clones.clone(implementation);
        Wallet(clone).initialize(owner);
        emit WalletDeployed(clone, owner);
        return clone;
    }

    function predictWalletAddress(bytes32 salt) external view returns (address predicted) {
        predicted = Clones.predictDeterministicAddress(implementation, salt, address(this));
    }

    function createWalletDeterministic(address owner, bytes32 salt) external returns (address) {
        address clone = Clones.cloneDeterministic(implementation, salt);
        Wallet(clone).initialize(owner);
        emit WalletDeployed(clone, owner);
        return clone;
    }
}

interface Wallet {
    function initialize(address _owner) external;
}
