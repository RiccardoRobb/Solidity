// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * 0x0d79df66BE487753B02D015Fb622DED7f0E9798d   DAI/USD
     * 0x9F6d70CDf08d893f0063742b51d3E9D1e18b7f74   Azuki/eth
     */
    constructor(address clOracleAddress) {
        priceFeed = AggregatorV3Interface(clOracleAddress);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getPriceDecimals() public view returns (uint) {
        return uint(priceFeed.decimals());
    }
}