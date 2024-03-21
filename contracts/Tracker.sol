//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTTracker is Ownable {
    mapping(uint256 => uint256) private _prices;

    error LengthMismatch();

    constructor() Ownable(_msgSender()) {}

    function setPrice(uint256 nftId, uint256 price) external onlyOwner {
        _prices[nftId] = price;
    }

    function setPrices(
        uint256[] calldata nftIds,
        uint256[] calldata prices
    ) external onlyOwner {
        if (nftIds.length != prices.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < nftIds.length; i++) {
            _prices[nftIds[i]] = prices[i];
        }
    }

    function getPrice(uint256 nftId) external view returns (uint256) {
        return _prices[nftId];
    }
}

interface INFTTracker {
    function getPrice(uint256 nftId) external view returns (uint256);
}
