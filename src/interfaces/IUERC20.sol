// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @notice Common interface for UERC20 tokens: ERC20 + metadata, creator attribution, and tokenURI.
interface IUERC20 is IERC20Metadata, IERC165 {
    /// @notice The address that created the token via the factory.
    function creator() external view returns (address);

    /// @notice Salt entropy included at deployment.
    function graffiti() external view returns (bytes32);

    /// @notice Stored metadata fields.
    function metadata()
        external
        view
        returns (string memory description, string memory website, string memory image, bytes memory extraData);

    /// @notice Base64-encoded JSON data URI of the token metadata.
    function tokenURI() external view returns (string memory);
}
