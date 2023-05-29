// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenWhitelist {
    function isWhitelisted(address) external view returns(bool);
    function getWLLength() external view returns(uint256);
    function addToWhitelistMassive(address[] calldata) external returns (bool);
    function removeFromWhitelistMassive(address[] calldata _subscriber) external returns (bool _success);

    event WLAddressAdded(address indexed addedAddress);
    event WLAddressRemoved(address indexed removedAddress);
}