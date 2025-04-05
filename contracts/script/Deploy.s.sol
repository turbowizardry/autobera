// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ControllerRegistry.sol";
import "../src/WalletFactory.sol";
import "../src/Wallet.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ControllerRegistry first
        ControllerRegistry registry = new ControllerRegistry();
        console.log("ControllerRegistry deployed at:", address(registry));

        // Deploy Wallet implementation
        Wallet walletImplementation = new Wallet();
        console.log("Wallet implementation deployed at:", address(walletImplementation));

        // Deploy WalletFactory with the implementation and registry
        WalletFactory factory = new WalletFactory(address(walletImplementation), address(registry));
        console.log("WalletFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
} 