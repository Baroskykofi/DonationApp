// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            , 
            int256 price, 
            , 
            , 
        ) = priceFeed.latestRoundData(); // ETH/USD price
        return uint256(price * 1e10); // Adjust to 18 decimal places
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // Convert ETH to USD
        return ethAmountInUsd;
    }
}