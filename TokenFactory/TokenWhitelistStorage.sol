// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TokenWhitelistStorage {
    uint256 public _whitelistLength;
    uint256 public _wlManCounter;
    address public tokenContract;

    mapping(address => bool) public _whitelist;
    mapping(address => bool) public _WLManagers;
}