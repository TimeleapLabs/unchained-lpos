// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./lib/Schnorr/SchnorrUser.sol";
import "./lib/IndexedArrayLib.sol";

contract ProofOfStake is SchnorrUser {
    using IndexedArrayLib for IndexedArrayLib.IndexedArray;
    using SafeERC20 for IERC20;

    IndexedArrayLib.IndexedArray private validators;

    struct Stake {
        uint256 amount;
        uint256 end;
        uint256[] nfts;
    }

    mapping(address => Stake) public stakes;

    address public stakingToken;
    address public nftToken;
    uint256 public minSchnorrParticipantStake;

    error AmountZero();
    error DurationZero();
    error NoStakeToExtend();

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 end,
        uint256[] nfts
    );

    event Extended(address indexed user, uint256 end);
    event Increased(address indexed user, uint256 amount, uint256[] nfts);
    event Withdrawn(address indexed user, uint256 amount, uint256[] nfts);

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

    function transferFromUser(uint256 amount, uint256[] memory nfts) internal {
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        for (uint256 i = 0; i < nfts.length; i++) {
            IERC721(nftToken).safeTransferFrom(
                msg.sender,
                address(this),
                nfts[i]
            );
        }
    }

    function transferToUser(uint256 amount, uint256[] memory nfts) internal {
        IERC20(stakingToken).safeTransfer(msg.sender, amount);

        for (uint256 i = 0; i < nfts.length; i++) {
            IERC721(nftToken).safeTransferFrom(
                address(this),
                msg.sender,
                nfts[i]
            );
        }
    }

    function stakeSanityChecks(uint256 amount, uint256 duration) internal pure {
        if (amount == 0) {
            revert AmountZero();
        }

        if (duration == 0) {
            revert DurationZero();
        }
    }

    function updateStakeValues(
        uint256 amount,
        uint256 duration,
        uint256[] memory nfts
    ) internal {
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].end += duration;

        for (uint256 i = 0; i < nfts.length; i++) {
            stakes[msg.sender].nfts.push(nfts[i]);
        }
    }

    function checkAddAsSubmitter() internal {
        if (
            stakes[msg.sender].amount >= minSchnorrParticipantStake &&
            !validators.has(msg.sender)
        ) {
            validators.add(msg.sender);
        }
    }

    function checkRemoveSubmitter() internal {
        if (validators.has(msg.sender)) {
            validators.remove(msg.sender);
        }
    }

    function stake(
        uint256 amount,
        uint256 duration,
        uint256[] calldata nfts
    ) external {
        stakeSanityChecks(amount, duration);
        transferFromUser(amount, nfts);
        updateStakeValues(amount, block.timestamp + duration, nfts);
        checkAddAsSubmitter();
        emit Staked(msg.sender, amount, block.timestamp + duration, nfts);
    }

    function extendStake(uint256 duration) external {
        if (stakes[msg.sender].end == 0) {
            revert NoStakeToExtend();
        }
        updateStakeValues(0, duration, new uint256[](0));
        emit Extended(msg.sender, stakes[msg.sender].end);
    }

    function increaseStake(uint256 amount, uint256[] calldata nfts) external {
        transferFromUser(amount, nfts);
        updateStakeValues(amount, 0, nfts);
        checkAddAsSubmitter();
        emit Increased(msg.sender, amount, nfts);
    }

    function getStake(address user) public view returns (Stake memory) {
        return stakes[user];
    }

    function withdraw() external {
        Stake memory userStake = stakes[msg.sender];
        transferToUser(userStake.amount, userStake.nfts);
        validators.remove(msg.sender);
        checkRemoveSubmitter();
        emit Withdrawn(msg.sender, userStake.amount, userStake.nfts);
    }
}
