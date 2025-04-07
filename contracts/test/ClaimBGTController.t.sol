// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console, Vm} from "forge-std/Test.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {Wallet} from "../src/Wallet.sol";
import {ControllerRegistry} from "../src/ControllerRegistry.sol";
import {WalletPermissions} from "../src/WalletPermissions.sol";
import {ClaimBGTController} from "../src/controllers/ClaimBGTController.sol";
import {IWallet} from "../src/interfaces/IWallet.sol";
import {IRewardVault} from "../src/interfaces/berachain/IRewardVault.sol";
import {IRewardVaultFactory} from "../src/interfaces/berachain/IRewardVaultFactory.sol";

contract MockRewardVault is IRewardVault {
    address public lastAccount;
    address public lastRecipient;
    uint256 public lastAmount;

    function getReward(address payable wallet) external override {
        lastRecipient = wallet;
        // Simulate reward transfer
        (bool success, ) = wallet.call{value: 1 ether}("");
        require(success, "Transfer failed");
    }
}

contract MockRewardVaultFactory is IRewardVaultFactory {
    mapping(address => address) public vaults;
    MockRewardVault public defaultVault;

    constructor() {
        defaultVault = new MockRewardVault();
    }

    function setVault(address lpToken, address vault) external {
        vaults[lpToken] = vault;
    }

    function getRewardVault(address lpToken) external view override returns (address) {
        address vault = vaults[lpToken];
        return vault == address(0) ? address(defaultVault) : vault;
    }
}

contract ClaimBGTControllerTest is Test {
    Wallet public walletImplementation;
    WalletFactory public factory;
    ControllerRegistry public controllerRegistry;
    WalletPermissions public walletPermissions;
    ClaimBGTController public claimBGTController;
    MockRewardVaultFactory public rewardVaultFactory;
    MockRewardVault public rewardVault;
    IWallet public wallet;

    address public owner;
    address public user1;
    address public lpToken;

    function setUp() public {
        owner = address(this);
        user1 = payable(makeAddr("user1"));
        lpToken = makeAddr("lpToken");

        // Deploy infrastructure
        controllerRegistry = new ControllerRegistry();
        walletPermissions = new WalletPermissions(address(controllerRegistry));
        walletImplementation = new Wallet();
        factory = new WalletFactory(
            address(walletImplementation),
            address(controllerRegistry),
            address(walletPermissions)
        );

        // Deploy reward vault system
        rewardVaultFactory = new MockRewardVaultFactory();
        rewardVault = new MockRewardVault();
        rewardVaultFactory.setVault(lpToken, address(rewardVault));

        // Deploy controller
        claimBGTController = new ClaimBGTController(address(rewardVaultFactory));

        // Register controller in registry
        controllerRegistry.registerController(
            address(claimBGTController),
            claimBGTController.permission(),
            claimBGTController.name(),
            claimBGTController.description()
        );

        // Create wallet for user1
        vm.startPrank(user1);
        wallet = IWallet(payable(factory.createWallet()));
        
        // Grant permission to controller
        walletPermissions.setPermission(address(wallet), address(claimBGTController), claimBGTController.permission(), true);

        vm.stopPrank();
    }

    function testClaimRewards() public {
        // Fund the reward vault
        vm.deal(address(rewardVault), 1 ether);

        // Initial balances
        uint256 initialWalletBalance = address(wallet).balance;

        // Claim rewards
        claimBGTController.claimRewards(address(wallet), lpToken);

        // Verify rewards were claimed
        assertEq(address(wallet).balance, initialWalletBalance + 1 ether);
        assertEq(rewardVault.lastRecipient(), address(wallet));
    }

    function testRevertIfNoVaultFound() public {
        address nonExistentLpToken = makeAddr("nonExistentLpToken");
        
        vm.expectRevert("No reward vault found for LP token");
        claimBGTController.claimRewards(address(wallet), nonExistentLpToken);
    }
} 