// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./Bip340/Bip340Ecrec.sol";

library SchnorrSignature {
    error InvalidSchorrSignature();

    struct Signature {
        uint256 rx;
        uint256 s;
    }

    function verify(
        Signature memory signature,
        bytes32 message,
        uint256 pubkey
    ) internal pure returns (bool) {
        return Bip340Ecrec.verify(pubkey, signature.rx, signature.s, message);
    }

    function safeVerify(
        Signature memory signature,
        bytes32 message,
        uint256 pubkey
    ) internal pure {
        if (!verify(signature, message, pubkey)) {
            revert InvalidSchorrSignature();
        }
    }
}
