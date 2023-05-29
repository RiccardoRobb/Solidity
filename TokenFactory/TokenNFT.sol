// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./interfaces/ITokenWhitelist.sol";
import "./interfaces/ITokenNFT.sol";
import "./TokenNFTStorage.sol";

contract TokenNFT is TokenNFTStorage, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable, ERC2981Upgradeable, ITokenNFT {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @notice Initializer
     * @param _tokenName token name
     * @param _tokenSymbol token symbol
     * @param _baseTokenURI token URI base
     * @param _creatorAddress creator address
     * @param _feesCollectorAddress fees collector address
     * @param _feesPercent fees percentage
     * @param _creatorPercent creator fees percentage
     * @param _baseCollectionPrice base collection price
     * @param _startDate token mint start date 
     */
    function initialize(string memory _tokenName, 
            string memory _tokenSymbol, 
            string memory _baseTokenURI,
            // uint256 _maxSupply,
            address _creatorAddress,
            address _feesCollectorAddress,
            uint256 _feesPercent,
            uint256 _creatorPercent,
            uint256 _baseCollectionPrice,
            uint256 _startDate) public initializer {
        // require(_feesPercent >= MIN_FEES_PERCENTAGE, "TokenNFT: BI precentage too low");
        require(_creatorPercent <= PERCENT_DIVIDER - _feesPercent, "TokenNFT: creator precentage too high"); 
        require(_startDate >= block.timestamp, "TokenNFT: Date not allowed"); 
        __ERC721_init(_tokenName, _tokenSymbol);
        baseTokenURI = _baseTokenURI;
        // maxSupply = _maxSupply;
        creatorAddress = _creatorAddress;
        feesCollectorAddress = _feesCollectorAddress;
        feesPercent = _feesPercent;
        creatorPercent = _creatorPercent;
        nftFactoryAddress = _msgSender();
        startDate = _startDate;

        baseCollectionPrice = _baseCollectionPrice;
    }

    /**
     * @dev Check if caller is the creator address or not.
     */
    modifier creatorOnly() {
        require(creatorAddress == _msgSender(), "TokenNFT: Not a creator");
        _;
    }

    /**
     * @dev Check if caller is the the NFT factory address or not.
     */
    modifier factoryOnly() {
        require(nftFactoryAddress == _msgSender(), "TokenNFT: Not an NFT factory");
        _;
    }

    /**
     * @dev enable reserve function, allowing creator to reserve NFTs before mint start date.
     * @param _useReserve boolean to allow or not to use reserve (default is false)
     */
    function enableReserveFunction(bool _useReserve) external override factoryOnly {
        useReserveFunction = _useReserve;
    }

    /**
     * @dev set token whitelist address for this token (factoryOnly)
     * @param _tokenWLAddr token whitelist address
     */
    function setTokenWLAddress(address _tokenWLAddr) external factoryOnly {
        require(_tokenWLAddr != address(0), "TokenNFT: WL address not allowed");
        tokenWLAddress = _tokenWLAddr;
    }

    /**
     * @dev get token fees percent for Fees collector address (blockcinvest)
     * @return feesPercent scaled by PERCENT_DIVIDER (= 1000000)
     */
    function getFeesPercent() external view override returns (uint256) {
        return feesPercent;
    }

    /**
    * @dev internal function to get URI base
    * @return baseTokenURI string with uri base address
    */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}. Read tokenURI in a tokenID
     * @param tokenId token ID
     * @return token URI string
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "TokenNFT: URI query for nonexistent token");

        string memory _tokenURI = tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
    * @dev mint a number of tokens based on current enumeration and sends it to minter applying fees for Blockinvests
    * @param _number number of tokens to be minted
    */
    function reserve(uint256 _number) external whenNotPaused creatorOnly {
        require(useReserveFunction, "TokenNFT: reserve function not allowed");
        require(block.timestamp < startDate, "TokenNFT: reserve can only be minted before start date");
        // uint256 totalMinted = tokenIdTracker.current();
        // require(totalMinted + _number <= maxSupply, "TokenNFT: too much tokens to mint");
        for (uint256 i = 0; i < _number; i++) {
            _safeMint(_msgSender(), tokenIdTracker.current());
            tokenIdTracker.increment();
        }
    }

    /**
    * @dev mint a token based on current enumeration and sends it to a recipient, with tokenURI formed by baseURI + counter
    */
    function mint() external payable whenNotPaused {
        require(block.timestamp >= startDate, "Start date not elapsed");
        // require(hasRole(MINTER_ROLE, _msgSender()), "TokenNFT: must have minter role to mint");
        require(msg.value >= baseCollectionPrice, "TokenNFT: not enough eth to mint");
        // require(tokenIdTracker.current() < maxSupply, "TokenNFT: max supply reached");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _safeMint(_msgSender(), tokenIdTracker.current());
        tokenIdTracker.increment();
    }

    /**
    * @dev burn a minted token ID
    * @param tokenId token Id to be burned
    */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TokenNFT: caller is not owner nor approved");
        _burn(tokenId);
        _resetTokenRoyalty(tokenId);
        if (bytes(tokenURIs[tokenId]).length != 0) {
            delete tokenURIs[tokenId];
        }
    }

    /**
    * @dev function called before any token transfer, checking for a whitelist and the recipient. it fails if whitelist present and recipient not whitelisted
    * @param from from address
    * @param to recipient address
    * @param tokenId token Id to be transferred
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable)  {
        super._beforeTokenTransfer(from, to, tokenId);
        require(tokenWLAddress == address(0) || (tokenWLAddress != address(0) && ITokenWhitelist(tokenWLAddress).isWhitelisted(to)), "TokenNFT: receiver not whitelisted");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        // ERC2981Upgradeable: 0x2baae9fd || ERC721EnumerableUpgradeable: 0x79f154c4 || IERC721Upgradeable: 0x80ac58cd
        return (interfaceId == type(ERC2981Upgradeable).interfaceId  || super.supportsInterface(interfaceId) );
    }

    /**
     * @dev pause token activities (creatorOnly)
     */
    function pause() external creatorOnly {
        _pause();
    }

    /**
     * @dev unpause token activities (creatorOnly)
     */
    function unpause() external creatorOnly {
        _unpause();
    }

    /** 
     * @dev Set a new creator address, transferring ownership of this contract (creatorOnly)
     * @param _newCreator new creator address
     */
    function setCreatorAddress(address _newCreator) external creatorOnly {
        require(_newCreator != address(0), "TokenNFT: new recipient is the zero address");
        creatorAddress = _newCreator;
        emit CreatorChanged(creatorAddress);
    }

    /** 
     * @dev set a new fees collector address (factoryOnly) 
     * @param _newFeesColl new fees collector address
     */
    function setNewFeesCollector(address _newFeesColl) external factoryOnly {
        feesCollectorAddress = _newFeesColl;
    }

    /** 
     * @dev set a new fees percentage (scaled by 10^6) (factoryOnly) 
     * @param _newFeesPercent new fees percentage
     */
    function setNewFeesPercentage(uint256 _newFeesPercent) external factoryOnly {
        feesPercent = _newFeesPercent;
    }

    /** 
     * @dev EIP2981 royalties implementation (creatorOnly)
     * @param _salePrice token id sale price
     * @return receiver royalties receiver address
     * @return royaltyAmount royalty amount, calculated based on sale price and creator fees percentage
     */
    function royaltyInfo(uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (creatorAddress, _salePrice * creatorPercent / PERCENT_DIVIDER);
    }

    /**
    * @dev withdraws value the resides in contract, splitting fees for fees collector address and creator
    */
    function withdraw() external payable {
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenNFT: No ethers to withdraw");
        bool success;
        // blockInvest fees
        uint256 biAmount = balance * feesPercent / PERCENT_DIVIDER;
        (success, ) = payable(feesCollectorAddress).call{value: biAmount}("");
        require(success, "TokenNFT: Transfer failed.");
        // creator fees
        uint256 creatorAmount = balance - biAmount;
        (success, ) = payable(creatorAddress).call{value: creatorAmount}("");
        require(success, "TokenNFT: Transfer failed.");
    }

}