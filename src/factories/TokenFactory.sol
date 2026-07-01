// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {SSTORE2} from "@solady/src/utils/SSTORE2.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @title TokenFactory
/// @notice Permissionless factory: register a token's creation code once (stored via SSTORE2), then
/// deploy it by id with CREATE2. See {ITokenFactory}.
contract TokenFactory is ITokenFactory {
    /// @notice SSTORE2 pointer to each implementation's creation code
    mapping(uint256 id => address pointer) public implementationOf;

    /// @notice Number of registered implementations (also the last-assigned id).
    uint256 public nextId;

    /// @dev Set immediately before the CREATE2 deploy and cleared after, so it is only readable by
    /// the token being constructed.
    DeploymentContext private _ctx;

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
        id = ++nextId;
        implementationOf[id] = pointer;
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
        address pointer = implementationOf[id];
        if (pointer == address(0)) revert UnknownImplementation(id);

        bytes memory initCode = SSTORE2.read(pointer);
        bytes32 salt = keccak256(abi.encode(id, msg.sender, graffiti, keccak256(data)));

        _ctx = DeploymentContext({creator: msg.sender, graffiti: graffiti, data: data});
        token = Create2.deploy(0, salt, initCode);
        delete _ctx;

        emit TokenCreated(token, msg.sender, id, data);
    }

    /// @inheritdoc ITokenFactory
    function getAddress(uint256 id, address creator, bytes32 graffiti, bytes32 dataHash)
        external
        view
        returns (address)
    {
        address pointer = implementationOf[id];
        if (pointer == address(0)) revert UnknownImplementation(id);
        bytes32 salt = keccak256(abi.encode(id, creator, graffiti, dataHash));
        return Create2.computeAddress(salt, keccak256(SSTORE2.read(pointer)), address(this));
    }
}
