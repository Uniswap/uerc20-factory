// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

bytes32 constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
bytes32 constant VERSION_HASH = keccak256("1");
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

error PermitExpired();
error InvalidPermitSignature();

/// @notice EIP-2612 permit state and verification. The EIP-712 domain separator is cached at
/// construction and recomputed if the chain id changes (fork safety).
struct Permit {
    bytes32 nameHash;
    address verifyingContract;
    uint256 cachedChainId;
    bytes32 cachedDomainSeparator;
    mapping(address owner => uint256 nonce) nonces;
}

using {init, domainSeparator, verify} for Permit global;

/// @notice Caches the EIP-712 domain; call once during construction with the token's own address.
function init(Permit storage self, string memory name, address verifyingContract) {
    self.nameHash = keccak256(bytes(name));
    self.verifyingContract = verifyingContract;
    self.cachedChainId = block.chainid;
    self.cachedDomainSeparator = _buildDomainSeparator(self);
}

/// @notice Current EIP-712 domain separator.
function domainSeparator(Permit storage self) view returns (bytes32) {
    if (block.chainid == self.cachedChainId) return self.cachedDomainSeparator;
    return _buildDomainSeparator(self);
}

/// @notice Verifies an EIP-2612 permit signature for `owner` and consumes their nonce.
/// @dev Reverts on an expired deadline or invalid signature.
function verify(
    Permit storage self,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) {
    if (block.timestamp > deadline) revert PermitExpired();
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, self.nonces[owner]++, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator(self), structHash));
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0) || signer != owner) revert InvalidPermitSignature();
}

function _buildDomainSeparator(Permit storage self) view returns (bytes32) {
    return keccak256(abi.encode(DOMAIN_TYPEHASH, self.nameHash, VERSION_HASH, block.chainid, self.verifyingContract));
}
