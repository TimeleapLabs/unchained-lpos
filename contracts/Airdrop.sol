// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Airdrop {
    using SafeERC20 for IERC20;

    struct AirdropData {
        address to;
        uint256 amount;
        uint256[] nftIds;
    }

    function distributeAirdrop(
        address tokenAddress,
        address nftAddress,
        AirdropData[] memory airdropData
    ) external {
        IERC20 token = IERC20(tokenAddress);
        IERC721 nft = IERC721(nftAddress);

        for (uint256 i = 0; i < airdropData.length; i++) {
            AirdropData memory data = airdropData[i];

            for (uint256 j = 0; j < data.nftIds.length; j++) {
                nft.safeTransferFrom(msg.sender, data.to, data.nftIds[j]);
            }

            token.transferFrom(msg.sender, data.to, data.amount);
        }
    }
}
