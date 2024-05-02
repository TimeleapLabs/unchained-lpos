// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Staking.sol";

contract Attacker is Ownable, ReentrancyGuard {
    IERC20 public token;
    UnchainedStaking public target;
    address public contractOwner;
    UnchainedStaking.EIP712Transfer[] private eip712Transfers;
    UnchainedStaking.Signature[] private signatures;

    // Custom event for attack failure
    event AttackFailed(string error);

    constructor(
        UnchainedStaking _target,
        address _tokenAddress
    ) Ownable(msg.sender) {
        target = _target;
        contractOwner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function stakeToStakingContract(
        uint256 duration,
        uint256 amount,
        uint256[] calldata nftIds
    ) external onlyOwner {
        target.stake(duration, amount, nftIds);
    }

    function setBls(bytes20 blsAddress) external onlyOwner {
        target.setBlsAddress(blsAddress);
    }

    function approve(address addr, uint256 amount) external onlyOwner {
        token.approve(addr, amount);
    }

    // Function to initiate the reentrancy attack
    function attack() external {
        attackAll();
    }
    function attackAll() internal {
        uint256 duration = 25 * 60 * 60 * 24;
        uint256 amount = 1 * 1e18;
        uint256[] memory nftIds = new uint256[](0);
        bool failed = false;

        // Keep track of individual function failures
        bool unstakeFailed = attackUnstake();
        bool recoverERC20Failed = attackRecoverERC20();
        bool stakeFailed = attackStake(duration, amount, nftIds);
        bool increaseStakeFailed = attackIncreaseStake(amount, nftIds);
        bool transferFailed = attackTransfer(eip712Transfers, signatures);

        // Check if attacks failed
        if (
            unstakeFailed && recoverERC20Failed && stakeFailed && transferFailed
        ) {
            failed = true;
        }

        // Emit attack failed event if all functions failed
        if (failed) {
            emit AttackFailed("AttackFailed");
        }
    }
    // Function to initiate the reentrancy attack on recoverERC20
    function attackRecoverERC20() internal returns (bool) {
        uint256 amount = 1 * 1e18;
        try target.recoverERC20(address(this), contractOwner, amount) {
            return false;
        } catch {
            return true;
        }
    }

    // Function to initiate the reentrancy attack on unstake
    function attackUnstake() internal returns (bool) {
        try target.unstake() {
            return false;
        } catch {
            return true;
        }
    }

    // Function to initiate the reentrancy attack on stake
    function attackStake(
        uint256 duration,
        uint256 amount,
        uint256[] memory nftIds
    ) internal returns (bool) {
        try target.stake(duration, amount, nftIds) {
            return false;
        } catch {
            return true;
        }
    }

    // Function to initiate the reentrancy attack on increaseStake
    function attackIncreaseStake(
        uint256 amount,
        uint256[] memory nftIds
    ) internal returns (bool) {
        try target.increaseStake(amount, nftIds) {
            return false;
        } catch {
            return true;
        }
    }

    // Function to initiate the reentrancy attack on transfer
    function attackTransfer(
        UnchainedStaking.EIP712Transfer[] memory eip712Transfers,
        UnchainedStaking.Signature[] memory signatures
    ) internal returns (bool) {
        try target.transfer(eip712Transfers, signatures) {
            return false;
        } catch {
            return true;
        }
    }

    // Fallback function to continuously call all attack functions
    fallback() external nonReentrant {
        attackAll();
    }
}
