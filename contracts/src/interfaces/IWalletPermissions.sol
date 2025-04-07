// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IWalletPermissions {
    struct Permission {
        bytes32 permissionKey;
        address controller;
        bool isApproved;
        uint256 approvedAt;
    }

    event PermissionUpdated(
        address indexed wallet,
        address indexed controller,
        bytes32 indexed permissionKey,
        bool isApproved
    );

    /// @notice Sets or revokes permission for a controller on a specific wallet
    /// @param wallet The wallet address to set permissions for
    /// @param controller The controller address to set permissions for
    /// @param permissionKey The permission key to set
    /// @param approved Whether to approve or revoke the permission
    function setPermission(
        address wallet,
        address controller,
        bytes32 permissionKey,
        bool approved
    ) external;

    /// @notice Gets all permissions for a wallet
    /// @param wallet The wallet address to get permissions for
    /// @return An array of Permission structs
    function getWalletPermissions(address wallet) external view returns (Permission[] memory);

    /// @notice Checks if a controller has a specific permission for a wallet
    /// @param wallet The wallet address to check permissions for
    /// @param controller The controller address to check
    /// @param permissionKey The permission key to check
    /// @return Whether the controller has the permission
    function hasPermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external view returns (bool);

    /// @notice Gets detailed permission info for a specific controller and permission key
    /// @param wallet The wallet address to get permission for
    /// @param controller The controller address to get permission for
    /// @param permissionKey The permission key to get
    /// @return The Permission struct containing all permission details
    function getPermission(
        address wallet,
        address controller,
        bytes32 permissionKey
    ) external view returns (Permission memory);

    /// @notice Gets the controller registry contract address
    /// @return The address of the controller registry contract
    function controllerRegistry() external view returns (address);
}
