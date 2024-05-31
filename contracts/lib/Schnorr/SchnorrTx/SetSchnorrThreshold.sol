// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../Bip340/Bip340Ecrec.sol";

library SetSchnorrThreshold {
    struct SchnorrThreshold {
        uint256 threshold;
        uint256 nonce;
    }

    bytes32 public constant SCHNORR_THRESHOLD_TYPEHASH =
        keccak256("SchnorrThreshold(uint256 threshold,uint256 nonce)");

    function hash(
        SchnorrThreshold memory threshold
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    SCHNORR_THRESHOLD_TYPEHASH,
                    threshold.threshold,
                    threshold.nonce
                )
            );
    }

    function eip712Hash(
        SchnorrThreshold memory threshold,
        bytes32 domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash(threshold))
            );
    }
}
