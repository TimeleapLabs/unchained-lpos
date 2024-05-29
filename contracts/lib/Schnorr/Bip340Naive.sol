// SPDX-License-Identifier: MIT

/*
 * This file is part of the Unchained project.
 * It was copied from the ZeroDAO project (https://github.com/zerodao-finance/bip340-solidity).
 * The original code is licensed under the MIT License.
 */

pragma solidity >=0.8.0;

import "./EllipticCurve.sol";
import "./Secp256k1.sol";

import "./Bip340.sol";
import "./Bip340Util.sol";

contract Bip340Naive is Bip340Verifier {
    /// Verifies a BIP340 signature parsed as `(rx, s)` form against a message
    /// `m` and a pubkey's x coord `px`.
    ///
    /// px - public key x coordinate
    /// rx - signature r commitment
    /// s - signature s proof
    /// m - message hash
    function verify(
        uint256 px,
        uint256 rx,
        uint256 s,
        bytes32 m
    ) public pure override returns (bool) {
        // Check pubkey is in range.
        if (px >= Secp256k1.PP) {
            return false;
        }

        // Let P = lift_x(int(pk)); fail if that fails.
        //
        // This *could* be precomputed and stored.
        (uint256 py, bool liftOk) = Bip340Util.liftX(px);
        if (!liftOk) {
            return false;
        }

        // Check pubkey is on curve.
        if (
            !EllipticCurve.isOnCurve(
                px,
                py,
                Secp256k1.AA,
                Secp256k1.BB,
                Secp256k1.PP
            )
        ) {
            return false;
        }

        return verifyFull(px, py, rx, s, m);
    }

    /// Verifies a BIP340 signature parsed as `(rx, s)` form against a message
    /// `m` and pubkey coords `px` and `py`.  The pubkey must already be on the
    /// curve because we skip some checks with it.
    ///
    /// px, py - public key coordinates
    /// rx - signature r commitment
    /// s - signature s proof
    /// m - message hash
    function verifyFull(
        uint256 _px,
        uint256 _py,
        uint256 rx,
        uint256 s,
        bytes32 m
    ) public pure returns (bool) {
        // Check rx and s are in-range.
        if (rx >= Secp256k1.PP || s >= Secp256k1.NN) {
            return false;
        }

        // Let e = int(hashBIP0340/challenge(bytes(r) || bytes(P) || m)) mod n.
        uint256 e = Bip340Util.computeChallenge(bytes32(rx), bytes32(_px), m);

        // Let R = s⋅G - e⋅P.
        // Weird scoping because we have to manipulate the stack here.
        (uint256 rvx, uint256 rvy) = (0, 0);
        {
            uint256 px = _px;
            uint256 py = _py;
            (uint256 sgx, uint256 sgy, uint256 sgz) = EllipticCurve.jacMul(
                s,
                Secp256k1.GX,
                Secp256k1.GY,
                1,
                Secp256k1.AA,
                Secp256k1.PP
            );
            (uint256 epx, uint256 epy, uint256 epz) = EllipticCurve.jacMul(
                e,
                px,
                py,
                1,
                Secp256k1.AA,
                Secp256k1.PP
            );

            // Check if it's safe to use jacAdd.
            if (
                Bip340Util.xToAffine(sgx, sgz, Secp256k1.PP) ==
                Bip340Util.xToAffine(epx, epz, Secp256k1.PP)
            ) {
                return false;
            }

            uint256 epy_inv = (Secp256k1.PP - epy) % Secp256k1.PP; // only have to flip the y coordinate
            (uint256 jrvx, uint256 jrvy, uint256 jrvz) = EllipticCurve.jacAdd(
                sgx,
                sgy,
                sgz,
                epx,
                epy_inv,
                epz,
                Secp256k1.PP
            );

            // Convert back to affine now that we're done.
            (rvx, rvy) = EllipticCurve.toAffine(jrvx, jrvy, jrvz, Secp256k1.PP);
        }

        // Fail if is_infinite(R).
        if (rvx == 0 && rvy == 0) {
            // this could be simpler
            return false;
        }

        // Fail if not has_even_y(R).
        if ((rvy & 1) != 0) {
            return false;
        }

        // Fail if x(R) ≠ r.
        bool res = (rvx == rx);
        return res; // if they match then all good!
    }
}
