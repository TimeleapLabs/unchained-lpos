//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DKenshi is ERC20 {
    constructor() ERC20("dKenshi", "dKNS") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}

contract DKatana is ERC721 {
    constructor() ERC721("dKatana", "dKAT") {
        for (uint i = 0; i < 100; i++) {
            _mint(msg.sender, i);
        }
    }
}
