// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./TokenNFT.sol";
import "./TokenWhitelist.sol";
import "./interfaces/ITokenFactoryNFT.sol";
import "./TokenFactoryNFTStorage.sol";

contract TokenFactoryNFT is TokenFactoryNFTStorage, ITokenFactoryNFT, AccessControlEnumerableUpgradeable {

    /**
     * @notice Initializer, setting caller as an admin for the factory
     */
    function initialize(address _admin, address _feesColl, uint256 _feesPercent) external initializer{
        defaultFeesCollector = _feesColl;
        defaultFeesPercentage = _feesPercent;

        _setupRole(ADMIN_ROLE, _admin);
        _setupRole(BI_ROLE, _feesColl);
    }

    /**
    * @dev grant role for new address (only same role) 
    * @param role role to be granted
    * @param account grant role's address
    */
    function grantRole(bytes32 role, address account) public override(AccessControlUpgradeable, IAccessControlUpgradeable) onlyRole(role) {
        _grantRole(role, account);
    }
    
    /**
    * @dev add deployed asset contract address to internal variables
    * @param _tokenToAdd, asset contract address to add
    */
    function addTokenContractAddress(address _tokenToAdd) internal {
        tokens[tokenCounter] = _tokenToAdd;
        tokenDeployed[_tokenToAdd] = true;
    }

    /**
    * @dev add deployed takn WL contract address to a token already deployed
    * @param _tokenAddress, token address
    * @param _tokenWLToAdd, token WL contract address to add
    */
    function addTokenWLContractAddress(address _tokenAddress, address _tokenWLToAdd) internal {
        require(tokenDeployed[_tokenAddress], "Tank index not allowed");
        whitelists[_tokenAddress] = _tokenWLToAdd;
        tokenWLDeployed[_tokenWLToAdd] = true;
    }

    /**
    * @dev deploy a new token contract, add its address to internal variables and change the ownership to new owner address (ADMIN_ROLE)
    * @param _tokenAddress, token address
    * @param _useReserveFunction, use reserve function or not
    */
    function enableReserveFunction(address _tokenAddress, bool _useReserveFunction) external onlyRole(ADMIN_ROLE) {
        TokenNFT(_tokenAddress).enableReserveFunction(_useReserveFunction);
        emit ReserveFunctionEnabled(_tokenAddress, _useReserveFunction);
    }

    /**
    * @dev deploy a new token contract, add its address to internal variables and change the ownership to new owner address (ADMIN_ROLE)
    * @param _name, name of the asset to be deployed
    * @param _symbol, symbol of the asset to be deployed
    * @param _baseTokenURI, base token URI
    * @param _creatorAddress, creator address
    * @param _creatorPercent, creator percentage
    * @param _startDate, start date for minting actions
    * @return address of the deployed token contract
    */
    function deployTokenNFT(string memory _name,
            string memory _symbol,
            string memory _baseTokenURI,
            address _creatorAddress,
            uint256 _creatorPercent,
            uint256 _baseCollectionPrice,
            uint256 _startDate) public override onlyRole(ADMIN_ROLE) returns (address) {
        TokenNFT newToken = new TokenNFT();
        newToken.initialize(_name, _symbol, _baseTokenURI, /*_maxSupply,*/ _creatorAddress,
                defaultFeesCollector, defaultFeesPercentage, _creatorPercent, _baseCollectionPrice, _startDate);
        addTokenContractAddress(address(newToken));
        emit TokenCreated(address(newToken), tokenCounter, _creatorAddress);
        tokenCounter++;
        return address(newToken);
    }

    /**
    * @dev deploy a new token WL contract, add its address to internal variables and change the ownership to new owner address (ADMIN_ROLE)
    * @param _tokenAddress, token address
    * @param _creator, creator address
    * @return address of the deployed token WL contract
    */
    function deployTokenWL(address _tokenAddress, address _creator) public override onlyRole(ADMIN_ROLE) returns (address) {
        require(tokenDeployed[_tokenAddress], "NFT token contract not deployed");
        TokenWhitelist newTokenWL = new TokenWhitelist(); //(_tokenAddress);
        newTokenWL.initialize(_tokenAddress);
        TokenNFT(_tokenAddress).setTokenWLAddress(address(newTokenWL));
        address[] memory creators = new address[](1);
        creators[0] = _creator;
        newTokenWL.addToWhitelistMassive(creators);
        addTokenWLContractAddress(_tokenAddress, address(newTokenWL));
        newTokenWL.transferOwnership(_creator);
        emit TokenWLCreated(_tokenAddress, address(newTokenWL), _creator);
        return address(newTokenWL);
    }

    /**
    * @dev deploy a new token and a new token WL contract calling internal functions (ADMIN_ROLE)
    * @param _name, name of the asset to be deployed
    * @param _symbol, symbol of the asset to be deployed
    * @param _baseTokenURI, base token URI
    * @param _creatorAddress, creator address
    * @param _creatorPercent, creator percentage
    * @param _startDate, start date for minting actions
    * @return addresses of the deployed token and token WL contracts
    */
    function deployTokenWithWL(string memory _name,
            string memory _symbol,
            string memory _baseTokenURI,
            // uint256 _maxSupply,
            address _creatorAddress,
            uint256 _creatorPercent,
            uint256 _baseCollectionPrice,
            uint256 _startDate) external override onlyRole(ADMIN_ROLE) returns (address, address) {
        address newTokenAddress = deployTokenNFT(_name, _symbol, _baseTokenURI, /*_maxSupply,*/ _creatorAddress,
                _creatorPercent, _baseCollectionPrice, _startDate/*, true*/);
        address newTokenWLaddress = deployTokenWL(newTokenAddress, _creatorAddress);
        return (newTokenAddress, newTokenWLaddress);
    }

    /** 
     * @dev set a new defaults (BI_ROLE) 
     * @param _newFeesColl new fees collector address 
     * @param _newFeesPercent new fees percentage (scaled by 10^6)
     */
    function setNewDefaults(address _newFeesColl, uint256 _newFeesPercent) external onlyRole(BI_ROLE) {
        defaultFeesCollector = _newFeesColl;
        defaultFeesPercentage = _newFeesPercent;
    }

    /** 
     * @dev set a new fees collector address for a deployed token (BI_ROLE) 
     * @param _nftToken token address
     * @param _newFeesColl new fees collector address
     */
    function setNewDefaultFeesCollector(address _nftToken, address _newFeesColl) external onlyRole(BI_ROLE) {
        require(tokenDeployed[_nftToken], "NFT token not deployed by this factory");
        TokenNFT(_nftToken).setNewFeesCollector(_newFeesColl);
    }

    /** 
     * @dev set a new fees collector address for a deployed token (BI_ROLE) 
     * @param _nftToken token address
     * @param _newFeesPercent new fees percentage (scaled by 10^6)
     */
    function setNewDefaultPercentage(address _nftToken, uint256 _newFeesPercent) external onlyRole(BI_ROLE) {
        require(tokenDeployed[_nftToken], "NFT token not deployed by this factory");
        TokenNFT(_nftToken).setNewFeesPercentage(_newFeesPercent);
    }

}