// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenFactoryNFT {
    function deployTokenWL(address _tokenAddress, address _creator) external returns (address);
    function deployTokenNFT(string calldata _name,
            string calldata _symbol,
            string calldata _baseTokenURI,
            address _creatorAddress,
            uint256 _creatorPercent,
            uint256 _baseCollectionPrice,
            uint256 _startDate) external returns (address);
    function deployTokenWithWL(string calldata _name,
            string calldata _symbol,
            string calldata _baseTokenURI,
            address _creatorAddress,
            uint256 _creatorPercent,
            uint256 _baseCollectionPrice,
            uint256 _startDate) external returns (address, address);

    event TokenCreated(
        address indexed newToken,
        uint256 indexed tokenCounter,
        address creator
    );
    event TokenWLCreated(
        address indexed tokenAddress,
        address indexed newTokenWL,
        address creator
    );
    event ReserveFunctionEnabled(address indexed token, bool useReserveFunction);
}