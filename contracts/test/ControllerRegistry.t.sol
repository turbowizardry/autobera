// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/ControllerRegistry.sol";

contract ControllerRegistryTest is Test {
    ControllerRegistry public registry;
    address public owner;
    address public controller;
    bytes32 public constant PERMISSION_KEY = keccak256("TEST_PERMISSION");
    string public constant CONTROLLER_NAME = "Test Controller";
    string public constant CONTROLLER_DESC = "Test Description";

    function setUp() public {
        owner = makeAddr("owner");
        controller = makeAddr("controller");
        vm.startPrank(owner);
        registry = new ControllerRegistry();
        vm.stopPrank();
    }

    function test_RegisterController() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();

        ControllerRegistry.ControllerInfo[] memory controllers = registry.getControllers(PERMISSION_KEY);
        assertEq(controllers.length, 1);
        assertEq(controllers[0].controller, controller);
        assertEq(controllers[0].name, CONTROLLER_NAME);
        assertEq(controllers[0].permissionKey, PERMISSION_KEY);
        assertEq(controllers[0].description, CONTROLLER_DESC);
        assertTrue(controllers[0].isActive);
    }

    function test_RegisterController_NotOwner() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();
    }

    function test_RegisterController_InvalidAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid controller address");
        registry.registerController(address(0), PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();
    }

    function test_RegisterController_InvalidPermissionKey() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid permission key");
        registry.registerController(controller, bytes32(0), CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();
    }

    function test_RegisterController_DuplicatePermissionKey() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.expectRevert("Permission key already registered");
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();
    }

    function test_DeactivateController() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        registry.deactivateController(PERMISSION_KEY, 0);
        vm.stopPrank();

        ControllerRegistry.ControllerInfo[] memory controllers = registry.getControllers(PERMISSION_KEY);
        assertFalse(controllers[0].isActive);
    }

    function test_DeactivateController_NotOwner() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();

        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        registry.deactivateController(PERMISSION_KEY, 0);
        vm.stopPrank();
    }

    function test_DeactivateController_InvalidIndex() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.expectRevert("Invalid index");
        registry.deactivateController(PERMISSION_KEY, 1);
        vm.stopPrank();
    }

    function test_HasPermission() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();

        assertTrue(registry.hasPermission(controller, PERMISSION_KEY));
    }

    function test_HasPermission_AfterDeactivation() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        registry.deactivateController(PERMISSION_KEY, 0);
        vm.stopPrank();

        assertFalse(registry.hasPermission(controller, PERMISSION_KEY));
    }

    function test_HasPermission_InvalidController() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();

        vm.expectRevert("Invalid controller address");
        registry.hasPermission(address(0), PERMISSION_KEY);
    }

    function test_HasPermission_InvalidPermissionKey() public {
        vm.startPrank(owner);
        registry.registerController(controller, PERMISSION_KEY, CONTROLLER_NAME, CONTROLLER_DESC);
        vm.stopPrank();

        vm.expectRevert("Invalid permission key");
        registry.hasPermission(controller, bytes32(0));
    }

    function test_HasPermission_UnregisteredKey() public {
        vm.expectRevert("Permission key not registered");
        registry.hasPermission(controller, keccak256("UNREGISTERED_KEY"));
    }
} 