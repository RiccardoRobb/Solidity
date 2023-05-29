// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TokenFactoryNFTStorage {
    bytes32 public constant BI_ROLE = keccak256("BI_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public tokenCounter;

    address public defaultFeesCollector;
    uint256 public defaultFeesPercentage;

    mapping(uint256 => address) public tokens;
    mapping(address => bool) public tokenDeployed;

    mapping(address => address) public whitelists;
    mapping(address => bool) public tokenWLDeployed;
}