// SPDX-License-Identifier: MIT

/*
 * This file is part of the Unchained project.
 * It was copied from the ZeroDAO project (https://github.com/zerodao-finance/bip340-solidity).
 * The original code is licensed under the MIT License.
 */

pragma solidity >=0.8.0;

import "./Secp256k1.sol";

import "./Bip340.sol";
import "./Bip340Util.sol";

contract Bip340Ecrec is Bip340Verifier {
    /// Uses the ecrecover hack to verify a schnorr signature more efficiently than it should.
    ///
    // Based on `https://hackmd.io/@nZ-twauPRISEa6G9zg3XRw/SyjJzSLt9`
    // ^ this line is un-doc-commented because solc is annoying
    function verify(
        uint256 px,
        uint256 rx,
        uint256 s,
        bytes32 m
    ) public pure override returns (bool) {
        // Check pubkey, rx, and s are in-range.
        if (px >= Secp256k1.PP || rx >= Secp256k1.PP || s >= Secp256k1.NN) {
            return false;
        }

        (address exp, bool ok) = Bip340Util.convToFakeAddr(rx);
        if (!ok) {
            return false;
        }

        uint256 e = Bip340Util.computeChallenge(bytes32(rx), bytes32(px), m);
        bytes32 sp = bytes32(Secp256k1.NN - mulmod(s, px, Secp256k1.NN));
        bytes32 ep = bytes32(Secp256k1.NN - mulmod(e, px, Secp256k1.NN));

        // 27 apparently used to signal even parity (which it will always have).
        address rvh = ecrecover(sp, 27, bytes32(px), ep);
        return rvh == exp; // if recovery fails we fail anyways
    }
}
