// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract TokenNFTStorage {
    uint256 public constant PERCENT_DIVIDER = 1000000;  // percentage divider, 6 decimals

    // uint256 public constant MIN_FEES_PERCENTAGE = 25000;  // min BI percentage = 2,5%

    CountersUpgradeable.Counter public tokenIdTracker;

    string public baseTokenURI;

    // uint256 public maxSupply;
    uint256 public startDate;
    uint256 public feesPercent; // creation fees for BI
    uint256 public creatorPercent; // royalties fees
    uint256 public baseCollectionPrice;

    // token WL address
    address public tokenWLAddress;
    address public creatorAddress;
    address public feesCollectorAddress;
    address public nftFactoryAddress;

    // Optional mapping for token URIs
    mapping (uint256 => string) public tokenURIs;

    bool public useReserveFunction;
}