//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title dKenshi
 * @dev ERC20 token contract for Kenshi (for testing purposes only)
 */
contract DKenshi is ERC20 {
    constructor() ERC20("dKenshi", "dKNS") {
        _mint(msg.sender, 1e10 * 10 ** decimals());
    }
}

/**
 * @title dKatana
 * @dev ERC721 token contract for Katana (for testing purposes only)
 */
contract DKatana is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("dKatana", "dKAT") Ownable(msg.sender) {}

    function mint(uint fromId, uint toId) external onlyOwner {
        for (uint i = fromId; i < toId; i++) {
            _mint(msg.sender, i);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.kenshi.io/katana/";
    }

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
