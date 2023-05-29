// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceConsumer.sol";

contract SimpleDEX {

    address public token;

    PriceConsumerV3 public ethUsdContract;
    uint256 public ethPriceDecimals;
    uint256 public ethPrice;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor(address _token, address oracleEthUsdPrice) {
        token = _token;
        ethUsdContract = new PriceConsumerV3(oracleEthUsdPrice);
    }

    receive() external payable {

    } 

    function getCLParameters() public {
        ethPriceDecimals = ethUsdContract.getPriceDecimals();
        ethPrice = uint256(ethUsdContract.getLatestPrice()); 
    }

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        require(amountTobuy > 0, "You need to send some ether");
        uint256 dexBalance = IERC20(token).balanceOf(address(this));

        getCLParameters();
        uint256 amountToSend = amountTobuy * ethPrice / (10 ** ethPriceDecimals);

        require(amountToSend <= dexBalance, "Not enough tokens in the reserve");
        // token.transfer(msg.sender, amountTobuy);
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        // token.transferFrom(msg.sender, address(this), amount);

        getCLParameters();
        uint256 amountToSend = amount * (10 ** ethPriceDecimals) / ethPrice;

        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        require(address(this).balance >= amountToSend, "Not enough ethers in the reserve");
        payable(msg.sender).transfer(amountToSend);
        emit Sold(amount);
    }

}