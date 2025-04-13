// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/WalletPermissions.sol";
import "../src/ControllerRegistry.sol";
import "../src/Wallet.sol";

contract WalletPermissionsTest is Test {
    WalletPermissions public permissions;
    ControllerRegistry public registry;
    Wallet public wallet;
    address public owner;
    address public controller;
    bytes32 public constant PERMISSION_KEY = keccak256("TEST_PERMISSION");
    string public constant CONTROLLER_NAME = "Test Controller";
    string public constant CONTROLLER_DESC = "Test Description";

    function setUp() public {
        owner = makeAddr("owner");
        controller = makeAddr("controller");
        
        // Deploy ControllerRegistry
        vm.startPrank(owner);
        registry = new ControllerRegistry();
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        
        // Deploy WalletPermissions
        permissions = new WalletPermissions(address(registry));
        
        // Deploy and initialize Wallet
        wallet = new Wallet();
        wallet.initialize(owner, address(registry), address(permissions));
        vm.stopPrank();
    }

    function test_ApprovePermission() public {
        vm.startPrank(owner);
        permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();

        assertTrue(permissions.hasPermission(address(wallet), controller, PERMISSION_KEY));
        
        WalletPermissions.Permission memory perm = permissions.getPermission(address(wallet), controller, PERMISSION_KEY);
        assertEq(perm.controller, controller);
        assertEq(perm.permissionKey, PERMISSION_KEY);
        assertTrue(perm.isApproved);
        assertEq(perm.approvedAt, block.timestamp);
    }

    function test_ApprovePermission_NotWalletOwner() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert("Not wallet owner");
        permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_ApprovePermission_InvalidController() public {
        address invalidController = makeAddr("invalidController");
        vm.startPrank(owner);
        vm.expectRevert("Invalid controller");
        permissions.approvePermission(address(wallet), invalidController, PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_RevokePermission() public {
        // First approve the permission
        vm.startPrank(owner);
        permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
        
        // Then revoke it
        permissions.revokePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();

        assertFalse(permissions.hasPermission(address(wallet), controller, PERMISSION_KEY));
        
        WalletPermissions.Permission memory perm = permissions.getPermission(address(wallet), controller, PERMISSION_KEY);
        assertFalse(perm.isApproved);
        assertEq(perm.approvedAt, 0);
    }

    function test_RevokePermission_NotWalletOwner() public {
        // First approve the permission
        vm.startPrank(owner);
        permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();

        // Try to revoke as non-owner
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert("Not wallet owner");
        permissions.revokePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_RevokePermission_NonExistentPermission() public {
        vm.startPrank(owner);
        vm.expectRevert("Permission does not exist");
        permissions.revokePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_RevokePermission_AlreadyRevoked() public {
        // First approve the permission
        vm.startPrank(owner);
        permissions.approvePermission(address(wallet), controller, PERMISSION_KEY);
        
        // Revoke it once
        permissions.revokePermission(address(wallet), controller, PERMISSION_KEY);
        
        // Try to revoke again
        vm.expectRevert("Permission already revoked");
        permissions.revokePermission(address(wallet), controller, PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_GetPermission_NonExistent() public {
        WalletPermissions.Permission memory perm = permissions.getPermission(address(wallet), controller, PERMISSION_KEY);
        assertEq(perm.controller, address(0));
        assertEq(perm.permissionKey, bytes32(0));
        assertFalse(perm.isApproved);
        assertEq(perm.approvedAt, 0);
    }
} 