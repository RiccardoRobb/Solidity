// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Token is ERC20, Ownable {

    constructor(string memory _tokenName, 
            string memory _tokenSymbol, 
            uint256 _supply) ERC20(_tokenName, _tokenSymbol) {
        _mint(msg.sender, _supply*(1e18));
    }

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount*(1e18));
    }

}