// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title ITokenFactory
/// @notice Generic, permissionless token factory. Token implementations are registered once as
/// blueprints (their creation code is stored on-chain), then deployed by `id` via CREATE2. The
/// factory never knows any token's config layout: it stores an opaque `data` blob that the token's
/// constructor reads back through `deployment()` and decodes itself.
interface ITokenFactory {
    /// @notice Context made available to a token during its construction (read via `deployment()`).
    /// @param creator The address that called `createToken` (trustworthy creator attribution).
    /// @param graffiti Caller-provided salt entropy, also surfaced to the token.
    /// @param data Opaque, token-defined config; the token decodes this itself.
    struct DeploymentContext {
        address creator;
        bytes32 graffiti;
        bytes data;
    }

    /// @notice Emitted when a token implementation's creation code is registered.
    event Registered(uint256 indexed id, address blueprint, bytes32 initCodeHash);

    /// @notice Emitted when a token is deployed. `id` + `initCodeHash` let indexers allowlist code off-chain.
    event TokenCreated(address indexed token, address indexed creator, uint256 indexed id, bytes data);

    /// @notice Thrown when `id` has no registered blueprint.
    error UnknownBlueprint(uint256 id);

    /// @notice Thrown when registering empty creation code.
    error EmptyInitCode();

    /// @notice Thrown on re-entrant `createToken` (would clobber the deployment context).
    error Reentrancy();

    /// @notice Registers a token implementation's creation code as a blueprint.
    /// @param initCode The full creation code (e.g. `type(MyToken).creationCode`).
    /// @return id The blueprint id to pass to `createToken`.
    function register(bytes calldata initCode) external returns (uint256 id);

    /// @notice Returns the deployment context for the token currently under construction.
    /// @dev Only meaningful when called by a token mid-construction (i.e. from its constructor).
    function deployment() external view returns (DeploymentContext memory);

    /// @notice Deploys a registered token implementation deterministically.
    /// @param id The blueprint id.
    /// @param data Opaque config passed to the token (decoded by the token itself).
    /// @param graffiti Extra salt entropy for address derivation.
    /// @return token The deployed token address.
    function createToken(uint256 id, bytes calldata data, bytes32 graffiti) external returns (address token);

    /// @notice Predicts the address a token will be deployed to.
    /// @param id The blueprint id.
    /// @param creator The `createToken` caller.
    /// @param graffiti Extra salt entropy.
    /// @param dataHash `keccak256(data)`.
    /// @return The deterministic token address.
    function getAddress(uint256 id, address creator, bytes32 graffiti, bytes32 dataHash) external view returns (address);
}
