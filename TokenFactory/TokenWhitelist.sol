// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ITokenWhitelist.sol";
import "./TokenWhitelistStorage.sol";

contract TokenWhitelist is TokenWhitelistStorage, OwnableUpgradeable, ITokenWhitelist {
    /**
     * @notice Initializer, setting caller as WL manager and the owner of the whitelist
     * @param _tokenContract NFT or erc1155 contract address
     */
    function initialize (address _tokenContract) external initializer {
        OwnableUpgradeable.__Ownable_init();
        tokenContract = _tokenContract;
        _addWLManagers(msg.sender);
    }

    /**
     * @notice check if caller is WL manager or the owner
     */
    modifier onlyWLOrOwner() {
        require(isWLManager(_msgSender()) || (owner() == _msgSender()), "Not a Whitelist Manager or an Owner!");
        _;
    }

    /*   WL Roles Mngmt  */
    /**
     * @notice add a WL manager, updating WL manager counter
     * @param account address to add as WL manager
     */
    function _addWLManagers(address account) internal {
        _wlManCounter++;
        _WLManagers[account] = true;
    }

    /**
     * @notice remove a WL manager, updating WL manager counter, avoiding to remove last manager
     * @param account address to remove as WL manager
     */
    function _removeWLManagers(address account) internal {
        require(_wlManCounter > 1, "Cannot remove last WL manager");
        _wlManCounter--;
        _WLManagers[account] = false;
    }

    /**
     * @notice check if an address is a WL manager
     * @param account address to be checked
     */
    function isWLManager(address account) public view returns (bool) {
        return _WLManagers[account];
    }

    /**
     * @notice add a WL manager, updating WL manager counter (onlyWLOrOwner)
     * @param account address to add as WL manager
     */
    function addWLManagers(address account) external onlyWLOrOwner {
        _addWLManagers(account);
    }

    /**
     * @notice remove a WL manager, updating WL manager counter, avoiding to remove last manager (onlyWLOrOwner)
     * @param account address to remove as WL manager
     */
    function removeWLManagers(address account) external onlyWLOrOwner {
        _removeWLManagers(account);
    }

    /**
     * @notice renounce to be a WL manager, updating WL manager counter (onlyWLOrOwner)
     */
    function renounceWLManager() external onlyWLOrOwner {
        _removeWLManagers(_msgSender());
    }

    /*  Whitelisting  Mngmt  */
    /**
     * @dev check if an address is whitelisted
     * @param _subscriber address to be checked
     * @return true if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) external view override returns(bool) {
        return _whitelist[_subscriber];
    }

    /**
     * @dev length of the whitelisted accounts
     * @return number of whitelisted addresses
     */
    function getWLLength() external view override returns(uint256) {
        return _whitelistLength;
    }

    /**
     * @dev remove the subscriber list from the whitelist (max 100)
     * @param _subscriber The subscriber list to remove from the whitelist
     * @return _success true or false
     */
    function removeFromWhitelistMassive(address[] calldata _subscriber) external override onlyWLOrOwner returns (bool _success) {
        require(_subscriber.length <= 100, "Too long list of addresses!");

        for (uint8 i = 0; i < _subscriber.length; i++) {
            // require(_subscriber[i] != address(0), "_subscriber is zero");
            if(_whitelist[_subscriber[i]]) {
                _whitelist[_subscriber[i]] = false;
                _whitelistLength--;
            }
        }
        return true;
    }

    /**
     * @dev Add the subscriber list to the whitelist (max 100)
     * @param _subscriber The subscriber list to add to the whitelist.
     * @return _success true or false
     */
    function addToWhitelistMassive(address[] calldata _subscriber) external override onlyWLOrOwner returns (bool _success) {
        require(_subscriber.length <= 100, "Too long list of addresses!");

        for (uint8 i = 0; i < _subscriber.length; i++) {
            // require(_subscriber[i] != address(0), "_subscriber is zero");
            if(!_whitelist[_subscriber[i]]) {
                _whitelist[_subscriber[i]] = true;
                _whitelistLength++;
            }
        }
        return true;
    }

}