//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title UnchainedStaking
 * @notice This contract allows users to stake ERC20 tokens and ERC721 NFTs,
 * offering functionalities to stake, unstake, extend stakes, and manage
 * slashing in case of misbehavior. It implements an EIP-712 domain for secure
 * off-chain signature verifications, enabling decentralized governance
 * actions like voting or slashing without on-chain transactions for each vote.
 * The contract includes a slashing mechanism where staked tokens can be
 * slashed (removed from the stake) if the majority of voting power agrees on a
 * misbehavior. Users can stake tokens and NFTs either as consumers or not,
 * affecting their roles within the ecosystem, particularly in governance or
 * voting processes.
 */
contract UnchainedStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 private _token;
    IERC721 private _nft;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Stake {
        uint256 amount;
        uint256 unlock;
        uint256[] nftIds;
        bool consumer;
    }

    struct Slash {
        address accused;
        uint256 amount;
        uint256 voted;
        bool slashed;
        mapping(address => bool) accusers;
    }

    struct EIP712Transfer {
        address from;
        address to;
        uint256 amount;
        uint256[] nonces;
    }

    struct EIP712Slash {
        address accused;
        address accuser;
        uint256 amount;
        bytes32 incident;
    }

    error WrongNFT();
    error WrongEIP712Signature();
    error AmountZero();
    error DurationZero();
    error NotUnlocked();
    error AlreadyStaked();
    error StakeZero();
    error Forbidden();
    error NonceUsed(uint256 index, uint256 nonce);
    error LengthMismatch();
    error NotConsumer(uint256 index);
    error InvalidSignature(uint256 index);
    error AlreadyAccused(uint256 index);
    error WrongAccused(uint256 index);
    error AlreadySlashed(uint256 index);
    error VotingPowerZero(uint256 index);

    mapping(address => mapping(uint256 => bool)) private _nonces;

    bytes32 immutable DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant EIP712_TRANSFER_TYPEHASH =
        keccak256(
            "EIP712Transfer(address from,address to,uint256 amount,uint256[] nonces)"
        );

    bytes32 constant EIP712_SLASH_TYPEHASH =
        keccak256(
            "EIP712Slash(address accused,address accuser,uint256 amount,bytes32 incident)"
        );

    uint256 private _slashLock;
    uint256 private _slashThreshold = 51;
    uint256 private _totalVotingPower;
    address private _slashCollectionAddr;

    mapping(address => Stake) private _stakes;
    mapping(bytes32 => Slash) private _slashes;
    mapping(bytes20 => address) private _blsToAddress;
    mapping(address => bytes20) private _addressToBls;

    bool private _acceptNft;

    event Slashed(
        address consumer,
        address accuser,
        uint256 amount,
        uint256 voted,
        bytes32 incident
    );

    event Staked(
        address user,
        uint256 unlock,
        uint256 amount,
        uint256[] nftIds,
        bool consumer
    );

    event UnStaked(address user, uint256 amount, uint256[] nftIds);
    event Extended(address user, uint256 unlock);
    event StakeIncreased(address user, uint256 amount, uint256[] nftIds);
    event BlsAddressChanged(address user, bytes32 from, bytes32 to);
    event SlashThresholdChanged(uint256 from, uint256 to);

    /**
     * @dev Modifier to temporarily allow the contract to receive NFTs.
     * This sets a flag to accept NFTs before the function executes and
     * resets it afterward. It's used to control the flow of NFT acceptance
     * within specific functions to ensure that NFTs can only be received
     * under certain conditions.
     */
    modifier nftReceiver() {
        _acceptNft = true;
        _;
        _acceptNft = false;
    }

    /**
     * @dev Contract constructor
     * @param tokenAddress Address of the stake token.
     * @param nftAddress Address of the nft.
     * @param slashLock Lock slashing until this block is reached.
     * @param slashCollectionAddr Address to collect slash penalties.
     * @param name Name of the EIP712 Domain.
     * @param version Version of the EIP712 Domain.
     */
    constructor(
        address tokenAddress,
        address nftAddress,
        uint256 slashLock,
        address slashCollectionAddr,
        string memory name,
        string memory version
    ) Ownable(msg.sender) {
        _token = IERC20(tokenAddress);
        _nft = IERC721(nftAddress);
        _slashLock = slashLock;
        _slashCollectionAddr = slashCollectionAddr;
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: name,
                version: version,
                chainId: getChainId(),
                verifyingContract: address(this)
            })
        );
    }

    /**
     * @dev Ensures that this contract can receive NFTs safely. Reverts if the NFT is not the expected one.
     * @param {} The address which called the `safeTransferFrom` function on the NFT contract.
     * @param {} The address which previously owned the token.
     * @param {} The NFT identifier which is being transferred.
     * @param {} Additional data with no specified format sent along with the call.
     * @return The selector to confirm the contract implements the ERC721Received interface.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (msg.sender != address(_nft)) {
            revert WrongNFT();
        }

        if (!_acceptNft) {
            revert Forbidden();
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Returns the current chain ID.
     * @return The current chain ID.
     */
    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Hashes an EIP712Domain struct to its EIP712 representation.
     * @param domain The EIP712Domain struct containing domain information.
     * @return The EIP712 hash of the domain.
     */
    function hash(EIP712Domain memory domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(domain.name)),
                    keccak256(bytes(domain.version)),
                    domain.chainId,
                    domain.verifyingContract
                )
            );
    }

    /**
     * @dev Hashes an EIP712Transfer struct to its EIP712 representation.
     * @param eip712Transfer The EIP712Transfer struct containing transfer details.
     * @return The EIP712 hash of the transfer.
     */
    function hash(
        EIP712Transfer memory eip712Transfer
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_TRANSFER_TYPEHASH,
                    eip712Transfer.from,
                    eip712Transfer.to,
                    eip712Transfer.amount,
                    keccak256(abi.encode(eip712Transfer.nonces))
                )
            );
    }

    /**
     * @dev Hashes an EIP712Slash struct to its EIP712 representation.
     * @param eip712Slash The EIP712Slash struct containing transfer details.
     * @return The EIP712 hash of the slash.
     */
    function hash(
        EIP712Slash memory eip712Slash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SLASH_TYPEHASH,
                    eip712Slash.accused,
                    eip712Slash.accuser,
                    eip712Slash.amount,
                    eip712Slash.incident
                )
            );
    }

    /**
     * @dev Called by a user to stake their tokens along with NFTs if desired, specifying whether the stake is for a consumer.
     * @param duration The duration for which the tokens and NFTs are staked.
     * @param amount The amount of tokens to stake.
     * @param nftIds An array of NFT IDs to stake along with the tokens.
     * @param consumer A boolean indicating whether the stake is for a consumer or not.
     */
    function stake(
        uint256 duration,
        uint256 amount,
        uint256[] memory nftIds,
        bool consumer
    ) external nonReentrant nftReceiver {
        if (amount == 0 && nftIds.length == 0) {
            revert AmountZero();
        }

        if (duration == 0) {
            revert DurationZero();
        }

        if (_stakes[_msgSender()].amount > 0) {
            revert AlreadyStaked();
        }

        if (amount > 0) {
            _stakes[_msgSender()].amount = amount;
            _totalVotingPower += amount;
            _token.safeTransferFrom(_msgSender(), address(this), amount);
        }

        _stakes[_msgSender()].consumer = consumer;
        _stakes[_msgSender()].unlock = block.timestamp + duration;

        for (uint256 i = 0; i < nftIds.length; i++) {
            _stakes[_msgSender()].nftIds.push(nftIds[i]);
            _nft.safeTransferFrom(_msgSender(), address(this), nftIds[i], "");
        }

        emit Staked(
            _msgSender(),
            _stakes[_msgSender()].unlock,
            amount,
            nftIds,
            consumer
        );
    }

    /**
     * @dev Called by a user to extend the duration of their existing stake.
     * @param duration The additional duration to add to the current stake's unlock time.
     */
    function extend(uint256 duration) external {
        if (duration == 0) {
            revert DurationZero();
        }

        if (_stakes[_msgSender()].amount == 0) {
            revert StakeZero();
        }

        _stakes[_msgSender()].unlock += duration;
        emit Extended(_msgSender(), _stakes[_msgSender()].unlock);
    }

    /**
     * @dev Called by a user to increase their stake amount and optionally add more NFTs to the stake.
     * @param amount The additional amount of tokens to add to the existing stake.
     * @param nftIds An array of additional NFT IDs to add to the stake.
     */
    function increaseStake(
        uint256 amount,
        uint256[] memory nftIds
    ) external nonReentrant nftReceiver {
        if (amount == 0 && nftIds.length == 0) {
            revert AmountZero();
        }

        if (_stakes[_msgSender()].amount == 0) {
            revert StakeZero();
        }

        if (amount > 0) {
            _stakes[_msgSender()].amount += amount;
            _totalVotingPower += amount;
            _token.safeTransferFrom(_msgSender(), address(this), amount);
        }

        for (uint256 i = 0; i < nftIds.length; i++) {
            _stakes[_msgSender()].nftIds.push(nftIds[i]);
            _nft.safeTransferFrom(_msgSender(), address(this), nftIds[i], "");
        }

        emit StakeIncreased(_msgSender(), _stakes[_msgSender()].amount, nftIds);
    }

    /**
     * @dev Called by a user to unstake their tokens and NFTs once the stake duration has ended.
     */
    function unstake() external nonReentrant {
        if (_stakes[_msgSender()].amount == 0) {
            revert StakeZero();
        }

        if (block.timestamp < _stakes[_msgSender()].unlock) {
            revert NotUnlocked();
        }

        uint256 amount = _stakes[_msgSender()].amount;
        uint256[] memory nftIds = _stakes[_msgSender()].nftIds;
        _stakes[_msgSender()].amount = 0;
        _stakes[_msgSender()].nftIds = new uint256[](0);

        if (amount > 0) {
            _totalVotingPower -= amount;
            _token.safeTransfer(_msgSender(), amount);
        }

        for (uint256 i = 0; i < nftIds.length; i++) {
            _nft.safeTransferFrom(address(this), _msgSender(), nftIds[i], "");
        }

        emit UnStaked(_msgSender(), amount, nftIds);
    }

    /**
     * @dev Allows a user to set or update their BLS (Boneh-Lynn-Shacham) address.
     * @param blsAddress The new BLS address to be set for the user.
     */
    function setBlsAddress(bytes20 blsAddress) external {
        bytes32 current = _addressToBls[_msgSender()];
        _addressToBls[_msgSender()] = blsAddress;
        _blsToAddress[blsAddress] = _msgSender();
        emit BlsAddressChanged(_msgSender(), current, blsAddress);
    }

    /**
     * @dev Retrieves the BLS address associated with a given EVM address.
     * @param evm The EVM address to query the associated BLS address.
     * @return The BLS address associated with the given EVM address.
     */
    function blsAddressOf(address evm) public view returns (bytes20) {
        return _addressToBls[evm];
    }

    /**
     * @dev Retrieves the EVM address associated with a given BLS address.
     * @param bls The BLS address to query the associated EVM address.
     * @return The EVM address associated with the given BLS address.
     */
    function evmAddressOf(bytes20 bls) public view returns (address) {
        return _blsToAddress[bls];
    }

    /**
     * @dev Retrieves the stake information associated with a given BLS address.
     * @param bls The BLS address to query the stake information.
     * @return The stake information associated with the given BLS address.
     */
    function stakeOf(bytes20 bls) public view returns (Stake memory) {
        return _stakes[evmAddressOf(bls)];
    }

    /**
     * @dev Retrieves the stake information associated with a given EVM address.
     * @param evm The EVM address to query the stake information.
     * @return The stake information associated with the given EVM address.
     */
    function stakeOf(address evm) public view returns (Stake memory) {
        return _stakes[evm];
    }

    /**
     * @dev Checks if the stake associated with a given address is marked as consumer.
     * @param addr The address to check the consumer flag for.
     * @return True if the stake is marked as consumer, false otherwise.
     */
    function isConsumer(address addr) public view returns (bool) {
        return _stakes[addr].consumer;
    }

    /**
     * @dev Verifies the authenticity of a transaction using EIP-712 typed data signing.
     * @param eip712Transfer The EIP712Transfer structure containing the transaction details.
     * @param signature The signature to verify the transaction.
     * @return True if the signature is valid and matches the transaction details, false otherwise.
     */
    function verify(
        EIP712Transfer memory eip712Transfer,
        Signature memory signature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(eip712Transfer))
        );
        address signer = ECDSA.recover(
            digest,
            signature.v,
            signature.r,
            signature.s
        );
        return signer == eip712Transfer.from;
    }

    /**
     * @dev Verifies the authenticity of a slash request using EIP-712 typed data signing.
     * @param eip712TSlash The EIP712Slash structure containing the slash request details.
     * @param signature The signature to verify the slash request.
     * @return True if the signature is valid and matches the slash request details, false otherwise.
     */
    function verify(
        EIP712Slash memory eip712TSlash,
        Signature memory signature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(eip712TSlash))
        );
        address signer = ECDSA.recover(
            digest,
            signature.v,
            signature.r,
            signature.s
        );
        return signer == eip712TSlash.accuser;
    }

    /**
     * @dev Transfers a batch of ERC20 tokens according to the specified ERC20Transfers and validates each transfer with a corresponding signature.
     * @param eip712Transfers An array of EIP712Transfer structures specifying the transfer details.
     * @param signatures An array of signatures corresponding to each EIP712Transfer to validate the transfers.
     */
    function transfer(
        EIP712Transfer[] memory eip712Transfers,
        Signature[] memory signatures
    ) external nonReentrant {
        if (eip712Transfers.length != signatures.length) {
            revert LengthMismatch();
        }

        for (uint i = 0; i < eip712Transfers.length; i++) {
            EIP712Transfer memory eip712Transfer = eip712Transfers[i];

            for (uint n = 0; n < eip712Transfer.nonces.length; n++) {
                if (_nonces[eip712Transfer.from][eip712Transfer.nonces[n]]) {
                    revert NonceUsed(i, eip712Transfer.nonces[n]);
                }

                _nonces[eip712Transfer.from][eip712Transfer.nonces[n]] = true;
            }

            if (!_stakes[eip712Transfer.from].consumer) {
                revert NotConsumer(i);
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712Transfer, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            _stakes[eip712Transfer.from].amount -= eip712Transfer.amount;
            _token.safeTransfer(eip712Transfer.to, eip712Transfer.amount);
        }
    }

    /**
     * @dev Processes a batch of slash requests against stakers for misbehaviour, validated by signatures.
     * Each slash request decreases the stake of the accused if the collective voting power of accusers exceeds a threshold.
     * @param eip712Slashes An array of EIP712Slash structures containing details of each slash request.
     * @param signatures An array of signatures corresponding to each slash request for validation.
     */
    function slash(
        EIP712Slash[] memory eip712Slashes,
        Signature[] memory signatures
    ) external nonReentrant {
        if (block.number <= _slashLock) {
            revert Forbidden();
        }

        if (eip712Slashes.length != signatures.length) {
            revert LengthMismatch();
        }

        uint256 threshold = (_totalVotingPower * _slashThreshold) / 100;

        for (uint i = 0; i < eip712Slashes.length; i++) {
            EIP712Slash memory eip712Slash = eip712Slashes[i];
            Slash storage slashData = _slashes[eip712Slash.incident];

            if (slashData.accusers[eip712Slash.accuser]) {
                revert AlreadyAccused(i);
            }

            if (slashData.accused != eip712Slash.accused) {
                revert WrongAccused(i);
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712Slash, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            Stake memory userStake = _stakes[eip712Slash.accuser];

            if (userStake.amount == 0) {
                revert VotingPowerZero(i);
            }

            slashData.voted += userStake.amount;
            slashData.accusers[eip712Slash.accuser] = true;

            if (slashData.voted >= threshold && !slashData.slashed) {
                slashData.slashed = true;
                _stakes[eip712Slash.accused].amount -= eip712Slash.amount;
                _token.safeTransfer(_slashCollectionAddr, eip712Slash.amount);
            }
        }
    }

    /**
     * @dev Sets the minimum percentage of total voting power required to
     * successfully execute a slash. Only callable by the contract owner.
     * The threshold must be at least 51% to ensure a majority vote.
     * @param threshold The new slashing threshold as a percentage.
     */
    function setSlashThreshold(uint256 threshold) external onlyOwner {
        if (threshold < 51) {
            revert Forbidden();
        }

        if (threshold > 100) {
            revert Forbidden();
        }

        emit SlashThresholdChanged(_slashThreshold, threshold);
        _slashThreshold = threshold;
    }

    /**
     * @dev Returns the current threshold for slashing to occur. This
     * represents the minimum percentage of total voting power that must agree
     * on a slash for it to be executed.
     * @return The slashing threshold as a percentage of total voting power.
     */
    function getSlashThreshold() external view returns (uint256) {
        return _slashThreshold;
    }

    /**
     * @dev Sends `amount` of ERC20 `token` from contract address
     * to `recipient`
     *
     * Useful if someone sent ERC20 tokens to the contract address by mistake.
     *
     * @param token The address of the ERC20 token contract.
     * @param recipient The address to which the tokens should be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function recoverERC20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (token == address(_token)) {
            revert Forbidden();
        }
        IERC20(token).safeTransfer(recipient, amount);
    }
}
