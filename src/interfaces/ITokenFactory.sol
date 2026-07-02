// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title ITokenFactory
/// @notice Permissionless factory. Token creation code is registered once as a reusable
/// implementation, keyed by its hash, then deployed via CREATE2. Config is passed as an opaque blob
/// the token decodes itself, so new token types are added by registration with no factory change.
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

    /// @notice Emitted when creation code is registered. `initCodeHash` keys the implementation and
    /// lets integrators allowlist code.
    /// @param pointer The storage contract holding the registered creation code.
    event Registered(bytes32 indexed initCodeHash, address pointer);

    /// @notice Emitted when a token is deployed.
    event TokenCreated(address indexed token, address indexed creator, bytes32 indexed initCodeHash, bytes data);

    error UnknownImplementation(bytes32 initCodeHash);
    error AlreadyRegistered(bytes32 initCodeHash);
    error EmptyInitCode();
    error Reentrancy();

    /// @notice Registers token creation code as a reusable implementation, keyed by its hash.
    /// @dev Reverts if the same creation code has already been registered.
    /// @return initCodeHash The implementation key to pass to `createToken`.
    function register(bytes calldata initCode) external returns (bytes32 initCodeHash);

    /// @notice Deployment context for the token currently under construction.
    function deployment() external view returns (DeploymentContext memory);

    /// @notice Deploys a registered implementation deterministically.
    /// @param initCodeHash The implementation key (hash of the registered creation code).
    /// @param data Opaque config decoded by the token.
    /// @param graffiti Extra salt entropy.
    function createToken(bytes32 initCodeHash, bytes calldata data, bytes32 graffiti) external returns (address token);

    /// @notice Predicts the address `createToken` would deploy to.
    function getAddress(bytes32 initCodeHash, address creator, bytes32 graffiti, bytes32 dataHash)
        external
        view
        returns (address);
}
