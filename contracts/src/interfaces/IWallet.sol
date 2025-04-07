// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IControllerRegistry.sol";
import "./IWalletPermissions.sol";

interface IWallet {
    /// @notice Emitted when a wallet operation is executed
    /// @param target The contract being called
    /// @param selector The function selector being called
    /// @param wallet The controller address executing the call
    /// @param value The amount of native token sent with the call
    event WalletOperation(
        address indexed target,
        bytes4 indexed selector,
        address indexed wallet,
        uint256 value
    );

    /// @notice Emitted when the permissions contract is updated
    /// @param newPermissions The address of the new permissions contract
    event PermissionsContractUpdated(
        address indexed newPermissions
    );

    /// @notice Initializes the wallet with owner and required contracts
    /// @param _owner The address that will own this wallet
    /// @param _controllerRegistry The address of the controller registry contract
    /// @param _walletPermissions The address of the wallet permissions contract
    function initialize(
        address _owner,
        address _controllerRegistry,
        address _walletPermissions
    ) external;

    /// @notice Allows the owner to execute arbitrary transactions
    /// @param target The contract to call
    /// @param value The amount of native token to send
    /// @param data The calldata to send
    function ownerExecute(
        address target,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Allows approved controllers to execute transactions
    /// @param target The contract to call
    /// @param value The amount of native token to send
    /// @param data The calldata to send
    /// @param permission The permission key required for this execution
    function controllerExecute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 permission
    ) external;

    /// @notice Gets the owner of the wallet
    /// @return The address of the wallet owner
    function owner() external view returns (address);

    /// @notice Gets the controller registry contract
    /// @return The address of the controller registry contract
    function controllerRegistry() external view returns (IControllerRegistry);

    /// @notice Gets the wallet permissions contract
    /// @return The address of the wallet permissions contract
    function walletPermissions() external view returns (IWalletPermissions);

    /// @notice Checks if the wallet has been initialized
    /// @return Whether the wallet has been initialized
    function initialized() external view returns (bool);

    /// @notice Allows the wallet to receive native tokens
    receive() external payable;
}
