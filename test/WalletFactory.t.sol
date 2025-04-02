// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console, Vm} from "forge-std/Test.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {Wallet} from "../src/Wallet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWallet {
    function owner() external view returns (address);
    function initialized() external view returns (bool);
}

contract WalletFactoryTest is Test {
    WalletFactory public walletFactory;
    address public implementation;
    address public deployer;
    address public user;

    function setUp() public {
        deployer = vm.addr(0x1);
        user = vm.addr(0x2);
        
        // Deploy the implementation contract first
        implementation = address(new Wallet());
        
        vm.startPrank(deployer);
        walletFactory = new WalletFactory(implementation);
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
        address wallet = walletFactory.createWallet(owner);
        
        // Verify the wallet was created correctly
        assertTrue(wallet != address(0));
        assertEq(IWallet(wallet).owner(), owner);
        assertTrue(IWallet(wallet).initialized());
    }

    function testCreateMultipleWallets() public {
        address owner1 = address(0x3);
        address owner2 = address(0x4);
        
        address wallet1 = walletFactory.createWallet(owner1);
        address wallet2 = walletFactory.createWallet(owner2);
        
        // Verify wallets are different
        assertTrue(wallet1 != wallet2);
        
        // Verify each wallet's ownership
        assertEq(IWallet(wallet1).owner(), owner1);
        assertEq(IWallet(wallet2).owner(), owner2);
    }

    function testCreateWalletWithZeroAddress() public {
        vm.expectRevert("Invalid owner");
        walletFactory.createWallet(address(0));
    }

    function testPredictWalletAddress() public {
        bytes32 salt = bytes32(uint256(1));
        address predicted = walletFactory.predictWalletAddress(salt);
        address actual = walletFactory.createWalletDeterministic(user, salt);
        
        // Verify prediction matches actual address
        assertEq(predicted, actual);
    }

    function testCreateDeterministicWallet() public {
        bytes32 salt = bytes32(uint256(1));
        address wallet = walletFactory.createWalletDeterministic(user, salt);
        
        // Verify the wallet was created correctly
        assertTrue(wallet != address(0));
        assertEq(IWallet(wallet).owner(), user);
        assertTrue(IWallet(wallet).initialized());
    }

    function testCreateDeterministicWalletDuplicate() public {
        bytes32 salt = bytes32(uint256(1));
        walletFactory.createWalletDeterministic(user, salt);
        
        // Attempting to create another wallet with the same salt should revert
        vm.expectRevert();
        walletFactory.createWalletDeterministic(user, salt);
    }

    function testDifferentSaltsDifferentAddresses() public {
        bytes32 salt1 = bytes32(uint256(1));
        bytes32 salt2 = bytes32(uint256(2));
        
        address wallet1 = walletFactory.createWalletDeterministic(user, salt1);
        address wallet2 = walletFactory.createWalletDeterministic(user, salt2);
        
        // Verify different salts produce different addresses
        assertTrue(wallet1 != wallet2);
    }
}
