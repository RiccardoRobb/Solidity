// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenNFT {
    function getFeesPercent() external view returns (uint256);
    function royaltyInfo(uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function enableReserveFunction(bool _useReserve) external;

    event CreatorChanged(address indexed creatorAddress);
}