// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./SchnorrTx/Transfer.sol";
import "./SchnorrTx/TransferNft.sol";
import "./SchnorrTx/TransferOwnership.sol";
import "./SchnorrTx/SetNftPrices.sol";
import "./SchnorrTx/SetSchnorrThreshold.sol";
import "./Signature.sol";

contract SchnorrUser {
    using SchnorrSignature for SchnorrSignature.Signature;
    using SchnorrTransfer for SchnorrTransfer.Transfer;
    using SchnorrNftTransfer for SchnorrNftTransfer.Transfer;
    using SchnorrTransferOwnership for SchnorrTransferOwnership.TransferOwnership;
    using SetNftPrices for SetNftPrices.NftPrices;
    using SetSchnorrThreshold for SetSchnorrThreshold.SchnorrThreshold;

    uint256 public owner;
    mapping(bytes32 => bool) public processed;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public eip712DomainHash;

    error AlreadyProcessed();

    constructor(
        string memory name,
        string memory version,
        uint256 initializer
    ) {
        owner = initializer;
        EIP712Domain memory domain = EIP712Domain(
            name,
            version,
            block.chainid,
            address(this)
        );
        eip712DomainHash = hash(domain);
    }

    function hash(
        EIP712Domain memory eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function checkForReplay(bytes32 eip712Hash) internal {
        if (processed[eip712Hash]) {
            revert AlreadyProcessed();
        }
        processed[eip712Hash] = true;
    }

    function transferOwnership(
        SchnorrTransferOwnership.TransferOwnership memory txn,
        SchnorrSignature.Signature memory schnorrSignature
    ) public {
        bytes32 eip712Hash = txn.eip712Hash(eip712DomainHash);

        checkForReplay(eip712Hash);
        schnorrSignature.safeVerify(eip712Hash, owner);

        owner = txn.to;
    }

    function verifyTransfer(
        SchnorrTransfer.Transfer memory txn,
        SchnorrSignature.Signature memory schnorrSignature
    ) public {
        bytes32 eip712Hash = txn.eip712Hash(eip712DomainHash);
        checkForReplay(eip712Hash);
        schnorrSignature.safeVerify(eip712Hash, owner);
    }

    function verifyTransferNft(
        SchnorrNftTransfer.Transfer memory txn,
        SchnorrSignature.Signature memory schnorrSignature
    ) public {
        bytes32 eip712Hash = txn.eip712Hash(eip712DomainHash);
        checkForReplay(eip712Hash);
        schnorrSignature.safeVerify(eip712Hash, owner);
    }

    function verifySetNftPrice(
        SetNftPrices.NftPrices memory prices,
        SchnorrSignature.Signature memory schnorrSignature
    ) public {
        bytes32 eip712Hash = prices.eip712Hash(eip712DomainHash);
        checkForReplay(eip712Hash);
        schnorrSignature.safeVerify(eip712Hash, owner);
    }

    function verifySetSchnorrThreshold(
        SetSchnorrThreshold.SchnorrThreshold memory threshold,
        SchnorrSignature.Signature memory schnorrSignature
    ) public {
        bytes32 eip712Hash = threshold.eip712Hash(eip712DomainHash);
        checkForReplay(eip712Hash);
        schnorrSignature.safeVerify(eip712Hash, owner);
    }

    function safeVerify(
        bytes32 eip712Hash,
        SchnorrSignature.Signature memory schnorrSignature
    ) public view {
        schnorrSignature.safeVerify(eip712Hash, owner);
    }
}
