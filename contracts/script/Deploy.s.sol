// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ControllerRegistry.sol";
import "../src/WalletFactory.sol";
import "../src/Wallet.sol";
import "../src/WalletPermissions.sol";
import "../src/controllers/ClaimBGTController.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ControllerRegistry first
        ControllerRegistry registry = new ControllerRegistry();
        console.log("ControllerRegistry deployed at:", address(registry));

        // Deploy WalletPermissions
        WalletPermissions permissions = new WalletPermissions(address(registry));
        console.log("WalletPermissions deployed at:", address(permissions));

        // Deploy Wallet implementation
        Wallet walletImplementation = new Wallet();
        console.log("Wallet implementation deployed at:", address(walletImplementation));

        // Deploy WalletFactory with the implementation, registry, and permissions
        WalletFactory factory = new WalletFactory(
            address(walletImplementation),
            address(registry),
            address(permissions)
        );
        console.log("WalletFactory deployed at:", address(factory));

        // Deploy ClaimBGTController
        ClaimBGTController claimBGTController = new ClaimBGTController(
            address(0x94Ad6Ac84f6C6FbA8b8CCbD71d9f4f101def52a8) // RewardVaultFactory address
        );
        console.log("ClaimBGTController deployed at:", address(claimBGTController));

        // Register ClaimBGTController in the registry
        registry.registerController(
            address(claimBGTController),
            claimBGTController.permission(),
            claimBGTController.name(),
            claimBGTController.description()
        );

        vm.stopBroadcast();
    }
} 