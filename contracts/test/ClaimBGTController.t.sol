// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/controllers/ClaimBGTController.sol";
import "../src/Wallet.sol";
import "../src/WalletPermissions.sol";
import "../src/ControllerRegistry.sol";
import "../src/interfaces/berachain/IRewardVault.sol";

contract MockRewardVaultFactory {
    mapping(address => address) public rewardVaults;
    
    function setRewardVault(address lpToken, address vault) external {
        rewardVaults[lpToken] = vault;
    }
    
    function getVault(address lpToken) external view returns (address) {
        return rewardVaults[lpToken];
    }
}

contract MockRewardVault is IRewardVault {
    bool public getRewardCalled;

    function getReward(address account, address recipient) external override returns (uint256) {
        getRewardCalled = true;
        return 0;
    }
}

contract ClaimBGTControllerTest is Test {
    ClaimBGTController public controller;
    Wallet public wallet;
    WalletPermissions public permissions;
    ControllerRegistry public registry;
    MockRewardVaultFactory public rewardVaultFactory;
    MockRewardVault public rewardVault;
    
    address public owner;
    address public lpToken;
    bytes32 public constant PERMISSION_KEY = keccak256("AUTO_CLAIM_BGT_V1");

    function setUp() public {
        owner = makeAddr("owner");
        lpToken = makeAddr("lpToken");
        
        // Deploy mock contracts
        rewardVaultFactory = new MockRewardVaultFactory();
        rewardVault = new MockRewardVault();
        
        // Set up reward vault
        rewardVaultFactory.setRewardVault(lpToken, address(rewardVault));
        
        // Deploy main contracts
        vm.startPrank(owner);
        registry = new ControllerRegistry();
        permissions = new WalletPermissions(address(registry));
        wallet = new Wallet();
        wallet.initialize(owner, address(registry), address(permissions));
        controller = new ClaimBGTController(address(rewardVaultFactory));
        
        // Register controller and approve permission
        registry.registerController(address(controller), PERMISSION_KEY, "Auto-claim BGT", "Controller for auto claiming BGT rewards");
        permissions.approvePermission(address(wallet), address(controller), PERMISSION_KEY);
        vm.stopPrank();
    }

    function test_Constructor() public {
        assertEq(controller.rewardVaultFactory(), address(rewardVaultFactory));
        assertEq(controller.owner(), owner);
        assertEq(controller.permission(), PERMISSION_KEY);
        assertEq(controller.name(), "Auto-claim BGT");
        assertEq(controller.description(), "Controller for auto claiming BGT rewards from reward vaults");
    }

    function test_ClaimRewards() public {
        vm.startPrank(owner);
        controller.claimRewards(address(wallet), lpToken);
        vm.stopPrank();

        assertTrue(rewardVault.getRewardCalled());
    }

    function test_ClaimRewards_NoRewardVault() public {
        address invalidLpToken = makeAddr("invalidLpToken");
        vm.startPrank(owner);
        vm.expectRevert("No reward vault found for LP token");
        controller.claimRewards(address(wallet), invalidLpToken);
        vm.stopPrank();
    }

    function test_ClaimRewards_NoPermission() public {
        // Revoke permission
        vm.startPrank(owner);
        permissions.revokePermission(address(wallet), address(controller), PERMISSION_KEY);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert("Permission denied");
        controller.claimRewards(address(wallet), lpToken);
        vm.stopPrank();
    }
}