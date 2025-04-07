// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IWallet.sol";

contract WalletPermissions {
    struct Permission {
        bytes32 permissionKey;
        address controller;
        bool isApproved;
        uint256 approvedAt;
    }

    // wallet => permissionKey => controller => Permission
    mapping(address => mapping(bytes32 => mapping(address => Permission))) public permissions;
    
    // wallet => all approved permissions
    mapping(address => Permission[]) public walletPermissions;

    IControllerRegistry public immutable controllerRegistry;

    event PermissionUpdated(
        address indexed wallet,
        address indexed controller,
        bytes32 indexed permissionKey,
        bool isApproved
    );

    constructor(address _controllerRegistry) {
        require(_controllerRegistry != address(0), "Invalid controller registry");
        controllerRegistry = IControllerRegistry(_controllerRegistry);
    }

    modifier onlyWalletOwner(address wallet) {
        require(msg.sender == IWallet(payable(wallet)).owner(), "Not wallet owner");
        _;
    }

    function setPermission(
        address wallet,
        address controller,
        bytes32 permissionKey,
        bool approved
    ) external onlyWalletOwner(wallet) {
        // Verify controller is registered and active
        require(controllerRegistry.hasPermission(controller, permissionKey), "Invalid controller");

        Permission storage perm = permissions[wallet][permissionKey][controller];
        
        // If permission doesn't exist, add it to the wallet's permission list
        if (perm.controller == address(0)) {
            perm.controller = controller;
            perm.permissionKey = permissionKey;
            if (approved) {
                walletPermissions[wallet].push(perm);
            }
        }

        perm.isApproved = approved;
        perm.approvedAt = approved ? block.timestamp : 0;

        emit PermissionUpdated(wallet, controller, permissionKey, approved);
    }

    function getWalletPermissions(address wallet) external view returns (Permission[] memory) {
        return walletPermissions[wallet];
    }

    function hasPermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external view returns (bool) {
        return permissions[wallet][permissionKey][controller].isApproved;
    }

    function getPermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external view returns (Permission memory) {
        return permissions[wallet][permissionKey][controller];
    }
} 