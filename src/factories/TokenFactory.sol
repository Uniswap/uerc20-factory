// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {SSTORE2} from "@solady/src/utils/SSTORE2.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @title TokenFactory
/// @notice Permissionless blueprint factory. Anyone can register a token implementation's creation
/// code once (stored via SSTORE2); tokens are then deployed by `id` with CREATE2, carrying only an
/// `id` + opaque config so per-deploy calldata stays small on L2. The factory is generic — it never
/// decodes a token's config — so new token types are added by registration, never a redeploy.
contract TokenFactory is ITokenFactory {
    /// @notice SSTORE2 pointer holding each blueprint's creation code. `id` starts at 1; 0 = unset.
    mapping(uint256 id => address pointer) public blueprintOf;

    /// @notice Number of registered blueprints; also the last-assigned id.
    uint256 public blueprintCount;

    /// @dev Context for the token currently being constructed. Set immediately before the CREATE2
    /// deploy and cleared immediately after, so it is only ever readable by that token's constructor.
    DeploymentContext private _ctx;

    /// @dev Re-entrancy flag guarding `createToken` against a malicious blueprint that re-enters
    /// during construction and would otherwise clobber `_ctx`.
    bool private _locked;

    modifier nonReentrant() {
        if (_locked) revert Reentrancy();
        _locked = true;
        _;
        _locked = false;
    }

    /// @inheritdoc ITokenFactory
    function register(bytes calldata initCode) external returns (uint256 id) {
        if (initCode.length == 0) revert EmptyInitCode();
        address pointer = SSTORE2.write(initCode);
        id = ++blueprintCount;
        blueprintOf[id] = pointer;
        emit Registered(id, pointer, keccak256(initCode));
    }

    /// @inheritdoc ITokenFactory
    function deployment() external view returns (DeploymentContext memory) {
        return _ctx;
    }

    /// @inheritdoc ITokenFactory
    function createToken(uint256 id, bytes calldata data, bytes32 graffiti)
        external
        nonReentrant
        returns (address token)
    {
        address pointer = blueprintOf[id];
        if (pointer == address(0)) revert UnknownBlueprint(id);

        bytes memory initCode = SSTORE2.read(pointer);
        // Full config participates in the address; the implementation is bound via `id`.
        bytes32 salt = keccak256(abi.encode(id, msg.sender, graffiti, keccak256(data)));

        _ctx = DeploymentContext({creator: msg.sender, graffiti: graffiti, data: data});
        token = _deploy(initCode, salt);
        delete _ctx;

        emit TokenCreated(token, msg.sender, id, data);
    }

    /// @inheritdoc ITokenFactory
    function getAddress(uint256 id, address creator, bytes32 graffiti, bytes32 dataHash)
        external
        view
        returns (address)
    {
        address pointer = blueprintOf[id];
        if (pointer == address(0)) revert UnknownBlueprint(id);
        bytes32 salt = keccak256(abi.encode(id, creator, graffiti, dataHash));
        return Create2.computeAddress(salt, keccak256(SSTORE2.read(pointer)), address(this));
    }

    /// @notice CREATE2-deploys `initCode`, bubbling the constructor's revert reason on failure.
    function _deploy(bytes memory initCode, bytes32 salt) private returns (address token) {
        assembly ("memory-safe") {
            token := create2(0, add(initCode, 0x20), mload(initCode), salt)
            // On failure `create2` returns 0 and leaves the constructor's revert data in returndata;
            // bubble it so token-specific errors (e.g. invalid config) propagate to the caller.
            if iszero(token) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
