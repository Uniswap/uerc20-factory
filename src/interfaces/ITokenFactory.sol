// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title ITokenFactory
/// @notice Permissionless factory. Token creation code is registered once as a reusable
/// implementation, then deployed by id via CREATE2. Config is passed as an opaque blob the token
/// decodes itself, so new token types are added by registration with no factory change.
interface ITokenFactory {
    /// @notice Context a token reads (via `deployment()`) during its construction.
    /// @param creator The `createToken` caller.
    /// @param graffiti Caller-provided salt entropy.
    /// @param data Opaque, token-defined config.
    struct DeploymentContext {
        address creator;
        bytes32 graffiti;
        bytes data;
    }

    /// @notice Emitted when creation code is registered. `initCodeHash` lets integrators allowlist code.
    /// @param pointer The storage contract holding the registered creation code.
    event Registered(uint256 indexed id, address pointer, bytes32 initCodeHash);

    /// @notice Emitted when a token is deployed.
    event TokenCreated(address indexed token, address indexed creator, uint256 indexed id, bytes data);

    error UnknownImplementation(uint256 id);
    error EmptyInitCode();
    error Reentrancy();

    /// @notice Registers token creation code as a reusable implementation.
    /// @return id The implementation id to pass to `createToken`.
    function register(bytes calldata initCode) external returns (uint256 id);

    /// @notice Deployment context for the token currently under construction.
    function deployment() external view returns (DeploymentContext memory);

    /// @notice Deploys a registered implementation deterministically.
    /// @param id The implementation id.
    /// @param data Opaque config decoded by the token.
    /// @param graffiti Extra salt entropy.
    function createToken(uint256 id, bytes calldata data, bytes32 graffiti) external returns (address token);

    /// @notice Predicts the address `createToken` would deploy to.
    function getAddress(uint256 id, address creator, bytes32 graffiti, bytes32 dataHash) external view returns (address);
}
