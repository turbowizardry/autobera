// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/controllers/BaseController.sol";

contract TestController is BaseController {
    constructor(address _rewardVaultFactory) BaseController(_rewardVaultFactory) Ownable(msg.sender) {
        permission = keccak256("TEST_PERMISSION");
        name = "Test Controller";
        description = "Test Description";
    }
}

contract BaseControllerTest is Test {
    TestController public controller;
    address public owner;
    address public rewardVaultFactory;
    address public newRewardVaultFactory;

    function setUp() public {
        owner = makeAddr("owner");
        rewardVaultFactory = makeAddr("rewardVaultFactory");
        newRewardVaultFactory = makeAddr("newRewardVaultFactory");
        
        vm.startPrank(owner);
        controller = new TestController(rewardVaultFactory);
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(controller.rewardVaultFactory(), rewardVaultFactory);
        assertEq(controller.owner(), owner);
        assertEq(controller.permission(), keccak256("TEST_PERMISSION"));
        assertEq(controller.name(), "Test Controller");
        assertEq(controller.description(), "Test Description");
    }

    function test_SetRewardVaultFactory() public {
        vm.startPrank(owner);
        controller.setRewardVaultFactory(newRewardVaultFactory);
        vm.stopPrank();

        assertEq(controller.rewardVaultFactory(), newRewardVaultFactory);
    }

    function test_SetRewardVaultFactory_NotOwner() public {
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        controller.setRewardVaultFactory(newRewardVaultFactory);
        vm.stopPrank();
    }

    function test_SetRewardVaultFactory_InvalidAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid factory address");
        controller.setRewardVaultFactory(address(0));
        vm.stopPrank();
    }
} 