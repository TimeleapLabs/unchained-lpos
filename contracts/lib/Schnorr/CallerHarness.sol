// SPDX-License-Identifier: MIT

/*
 * This file is part of the Unchained project.
 * It was copied from the ZeroDAO project (https://github.com/zerodao-finance/bip340-solidity).
 * The original code is licensed under the MIT License.
 */

pragma solidity >=0.8.0;

import "./Bip340.sol";

/// Silly little harness that let's us capture return value and gas used during
/// a `.transact` call.
contract CallerHarness {
    event VerifyResult(bool ok, uint256 gasUsed);

    function verifySig(
        Bip340Verifier verif,
        uint256 px,
        uint256 rx,
        uint256 s,
        bytes32 m
    ) public returns (bool) {
        uint256 a = gasleft();
        bool ok = verif.verify(px, rx, s, m);
        uint256 b = gasleft();
        emit VerifyResult(ok, a - b);

        return ok;
    }
}
