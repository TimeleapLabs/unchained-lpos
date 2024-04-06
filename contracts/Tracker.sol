//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTTracker
 * @dev Contract to track the prices of NFTs
 */
contract NFTTracker is Ownable {
    mapping(uint256 => uint256) private _prices;

    error LengthMismatch();

    constructor() Ownable(_msgSender()) {}

    /**
     * @dev Set the price of an NFT
     * @param nftId The id of the NFT
     * @param price The price of the NFT
     */
    function setPrice(uint256 nftId, uint256 price) external onlyOwner {
        _prices[nftId] = price;
    }

    /**
     * @dev Set the prices of multiple NFTs
     * @param nftIds The ids of the NFTs
     * @param prices The prices of the NFTs
     */
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

    /**
     * @dev Get the price of an NFT
     * @param nftId The id of the NFT
     * @return The price of the NFT
     */
    function getPrice(uint256 nftId) external view returns (uint256) {
        return _prices[nftId];
    }
}

interface INFTTracker {
    function getPrice(uint256 nftId) external view returns (uint256);

    function setPrice(uint256 nftId, uint256 price) external;
}
