// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../Bip340/Bip340Ecrec.sol";

library SchnorrTransfer {
    struct Transfer {
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
    }

    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address from,address to,uint256 amount,uint256 nonce)"
        );

    function hash(Transfer memory transfer) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    TRANSFER_TYPEHASH,
                    transfer.from,
                    transfer.to,
                    transfer.amount,
                    transfer.nonce
                )
            );
    }

    function eip712Hash(
        Transfer memory transfer,
        bytes32 domainSeparator
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, hash(transfer))
            );
    }
}
