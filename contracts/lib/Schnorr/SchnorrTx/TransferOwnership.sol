// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../Bip340/Bip340Ecrec.sol";

library SchnorrTransferOwnership {
    struct TransferOwnership {
        uint256 to;
        uint256 nonce;
    }

    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256("TransferOwnership(uint256 to,uint256 nonce)");

    function hash(
        TransferOwnership memory transfer
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(TRANSFER_TYPEHASH, transfer.to, transfer.nonce)
            );
    }

    function eip712Hash(
        TransferOwnership memory transfer,
        bytes32 domainSeparator
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash(transfer))
            );
    }
}
