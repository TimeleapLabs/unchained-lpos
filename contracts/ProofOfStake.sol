// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "./lib/Schnorr/SchnorrUser.sol";
import "./lib/IndexedArrayLib.sol";

contract ProofOfStake is SchnorrUser {
    using IndexedArrayLib for IndexedArrayLib.IndexedArray;
    IndexedArrayLib.IndexedArray private validators;

    constructor(
        uint256 shcnorrOwner
    ) SchnorrUser("Unchained Proof of Stake", "1.0.0", shcnorrOwner) {}

    function getValidators() external view returns (address[] memory) {
        return validators.getAll();
    }

    function getValidators(
        uint256 start,
        uint256 end
    ) external view returns (address[] memory) {
        return validators.slice(start, end);
    }
}
