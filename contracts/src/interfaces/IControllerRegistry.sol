// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IControllerRegistry {
    struct ControllerInfo {
        address controller;
        string name;           // e.g., "Claim BGT"
        bytes32 permissionKey; // e.g., "CLAIM_BGT"
        string version;        // e.g., "v1.0.1"
        string description;
        bool isActive;
    }

    event ControllerRegistered(
        address indexed controller,
        bytes32 indexed permissionKey,
        string version
    );

    event ControllerDeactivated(
        address indexed controller,
        bytes32 indexed permissionKey
    );

    /// @notice Registers a new controller with specified permissions
    /// @param controller The address of the controller contract
    /// @param permissionKey The unique identifier for the permission type
    /// @param name Human-readable name for the controller
    /// @param version Version string for the controller
    /// @param description Detailed description of the controller's purpose
    function registerController(
        address controller,
        bytes32 permissionKey,
        string calldata name,
        string calldata version,
        string calldata description
    ) external;

    /// @notice Deactivates a controller for a specific permission
    /// @param permissionKey The permission key to deactivate
    /// @param index The index of the controller in the permission's array
    function deactivateController(
        bytes32 permissionKey,
        uint index
    ) external;

    /// @notice Gets all controllers registered for a specific permission
    /// @param permissionKey The permission key to query
    /// @return Array of ControllerInfo structs
    function getControllers(
        bytes32 permissionKey
    ) external view returns (ControllerInfo[] memory);

    /// @notice Checks if a controller has a specific permission
    /// @param controller The controller address to check
    /// @param permissionKey The permission key to verify
    /// @return bool indicating if the controller has the permission and is active
    function hasPermission(
        address controller,
        bytes32 permissionKey
    ) external view returns (bool);

    /// @notice Gets all controllers for a specific permission key
    /// @param permissionKey The permission key to query
    /// @return Array of controller addresses that have this permission
    function controllersByPermission(
        bytes32 permissionKey,
        uint256 index
    ) external view returns (ControllerInfo memory);

    /// @notice Gets the owner of the registry
    /// @return The address of the owner
    function owner() external view returns (address);
}