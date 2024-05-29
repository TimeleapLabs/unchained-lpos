// SPDX-License-Identifier: UNLICENSED

/*
 * This file is part of the Unchained project.
 * It was copied from the ZeroDAO project (https://github.com/zerodao-finance/bip340-solidity).
 * The original code is licensed under the MIT License.
 */

pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
