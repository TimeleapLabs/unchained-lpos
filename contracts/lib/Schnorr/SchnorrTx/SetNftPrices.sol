// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../Bip340/Bip340Ecrec.sol";

library SetNftPrices {
    struct NftPrices {
        uint256[] nfts;
        uint256[] prices;
        uint256 nonce;
    }

    bytes32 public constant NFT_PRICES_TYPEHASH =
        keccak256("NftPrices(uint256[] nfts,uint256[] prices,uint256 nonce)");

    function hash(NftPrices memory set) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    NFT_PRICES_TYPEHASH,
                    keccak256(abi.encodePacked(set.nfts)),
                    keccak256(abi.encodePacked(set.prices)),
                    set.nonce
                )
            );
    }

    function eip712Hash(
        NftPrices memory prices,
        bytes32 domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash(prices))
            );
    }
}
