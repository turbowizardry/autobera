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

    IControllerRegistry public immutable controllerRegistry;

    event PermissionApproved(
        address indexed wallet,
        address indexed controller,
        bytes32 indexed permissionKey,
        uint256 approvedAt
    );

    event PermissionRevoked(
        address indexed wallet,
        address indexed controller,
        bytes32 indexed permissionKey,
        uint256 revokedAt
    );

    constructor(address _controllerRegistry) {
        require(_controllerRegistry != address(0), "Invalid controller registry");
        controllerRegistry = IControllerRegistry(_controllerRegistry);
    }

    modifier onlyWalletOwner(address wallet) {
        require(msg.sender == IWallet(payable(wallet)).owner(), "Not wallet owner");
        _;
    }

    function approvePermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external onlyWalletOwner(wallet) {
        // Verify controller is registered and active
        require(controllerRegistry.hasPermission(controller, permissionKey), "Invalid controller");

        Permission storage perm = permissions[wallet][permissionKey][controller];
        
        // If permission doesn't exist, create it
        if (perm.controller == address(0)) {
            perm.controller = controller;
            perm.permissionKey = permissionKey;
        }

        perm.isApproved = true;
        perm.approvedAt = block.timestamp;
        emit PermissionApproved(wallet, controller, permissionKey, block.timestamp);
    }

    function revokePermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external onlyWalletOwner(wallet) {
        Permission storage perm = permissions[wallet][permissionKey][controller];
        require(perm.controller != address(0), "Permission does not exist");
        require(perm.isApproved, "Permission already revoked");

        perm.isApproved = false;
        perm.approvedAt = 0;
        emit PermissionRevoked(wallet, controller, permissionKey, block.timestamp);
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