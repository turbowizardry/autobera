// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console, Vm} from "forge-std/Test.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {Wallet} from "../src/Wallet.sol";
import {ControllerRegistry} from "../src/ControllerRegistry.sol";
import {WalletPermissions} from "../src/WalletPermissions.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWallet {
    function owner() external view returns (address);
    function initialized() external view returns (bool);
}

contract WalletFactoryTest is Test {
    WalletFactory public walletFactory;
    ControllerRegistry public controllerRegistry;
    WalletPermissions public walletPermissions;
    address public implementation;
    address public deployer;
    address public user;

    function setUp() public {
        deployer = vm.addr(0x1);
        user = vm.addr(0x2);
        
        // Deploy the implementation contract first
        implementation = address(new Wallet());
        controllerRegistry = new ControllerRegistry();
        walletPermissions = new WalletPermissions(address(controllerRegistry));
        
        vm.startPrank(deployer);
        walletFactory = new WalletFactory(
            implementation,
            address(controllerRegistry),
            address(walletPermissions)
        );
        vm.stopPrank();
        
        assertEq(walletFactory.owner(), deployer);
    }
    
    function testOwner() public view {
        // Test that the contract's owner is correct
        assertEq(walletFactory.owner(), vm.addr(0x1));
    }

    function testTransferOwnership() public {
        address newOwner = address(0x2);
        
        // Start prank as the current owner
        vm.startPrank(vm.addr(0x1));
        walletFactory.transferOwnership(newOwner);
        vm.stopPrank();
        
        assertEq(walletFactory.owner(), newOwner);
    }

    function testCreateWallet() public {
        address owner = address(0x3);

        vm.startPrank(owner);
        address wallet = walletFactory.createWallet();
        vm.stopPrank();
        
        // Verify the wallet was created correctly
        assertTrue(wallet != address(0));
        assertEq(IWallet(wallet).owner(), owner);
        assertTrue(IWallet(wallet).initialized());
    }

    function testCreateMultipleWallets() public {
        address owner1 = address(0x3);
        address owner2 = address(0x4);
        
        vm.startPrank(owner1);
        address wallet1 = walletFactory.createWallet();
        vm.stopPrank();

        vm.startPrank(owner2);
        address wallet2 = walletFactory.createWallet();
        vm.stopPrank();
        
        // Verify wallets are different
        assertTrue(wallet1 != wallet2);
        
        // Verify each wallet's ownership
        assertEq(IWallet(wallet1).owner(), owner1);
        assertEq(IWallet(wallet2).owner(), owner2);
    }
}
