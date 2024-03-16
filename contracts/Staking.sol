//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// TODO: Should there be a max voting power?

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

    struct SlashInfo {
        address accused;
        uint256 amount;
        uint256 voted;
        bool slashed;
        bytes32 incident;
    }

    struct Slash {
        SlashInfo info;
        mapping(address => bool) accusers;
    }

    struct ParamsInfo {
        address token;
        address nft;
        uint256 threshold;
        uint256 expiration;
        address collector;
        uint256 voted;
        uint256 nonce;
        bool accepted;
    }

    struct Params {
        ParamsInfo info;
        mapping(address => bool) requesters;
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

    struct EIP712SlashKey {
        address accused;
        uint256 amount;
        bytes32 incident;
    }

    struct EIP712SetParams {
        address requester;
        address token;
        address nft;
        uint256 threshold;
        uint256 expiration;
        address collector;
        uint256 nonce;
    }

    struct EIP712SetParamsKey {
        address token;
        address nft;
        uint256 threshold;
        uint256 expiration;
        address collector;
        uint256 nonce;
    }

    struct EIP712SetSigner {
        address staker;
        address signer;
    }

    error WrongNFT();
    error WrongEIP712Signature();
    error AmountZero();
    error DurationZero();
    error AddressZero();
    error NotUnlocked();
    error AlreadyStaked();
    error AddressInUse();
    error BlsNotSet();
    error StakeZero();
    error Forbidden();
    error NonceUsed(uint256 index, uint256 nonce);
    error LengthMismatch();
    error NotConsumer(uint256 index);
    error InvalidSignature(uint256 index);
    error AlreadyAccused(uint256 index);
    error VotingPowerZero(uint256 index);
    error AlreadyVoted(uint256 index);
    error TopicExpired(uint256 index);
    error StakeExpiresBeforeVote(uint256 index);

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

    bytes32 constant EIP712_SLASH_KEY_TYPEHASH =
        keccak256(
            "EIP712Slash(address accused,address accuser,uint256 amount,bytes32 incident)"
        );

    bytes32 constant EIP712_SET_SIGNER_TYPEHASH =
        keccak256("EIP712SetSigner(address staker,address signer)");

    bytes32 constant EIP712_SET_PARAMS_TYPEHASH =
        keccak256(
            "EIP712SetParams(address requester,address token,address nft,uint256 threshold,uint256 expiration,address collector,uint256 nonce)"
        );

    bytes32 constant EIP712_SET_PARAMS_KEY_TYPEHASH =
        keccak256(
            "EIP712SetParams(address token,address nft,uint256 threshold,uint256 expiration,address collector,uint256 nonce)"
        );

    uint256 private _consensusLock;
    uint256 private _consensusThreshold = 51;
    uint256 private _votingTopicExpiration = 1 days;
    uint256 private _totalVotingPower;
    address private _slashCollectionAddr;

    mapping(address => Stake) private _stakes;
    mapping(bytes32 => Slash) private _slashes;
    mapping(bytes32 => bool) private _incidentTracker;

    mapping(bytes20 => address) private _blsToAddress;
    mapping(address => bytes20) private _addressToBls;

    mapping(address => address) private _signerToStaker;
    mapping(address => address) private _stakerToSigner;

    mapping(uint256 => bool) private _setParamsTracker;
    mapping(bytes32 => Params) private _setParams;

    mapping(bytes32 => uint256) private _firstReported;

    bool private _acceptNft;

    event Accused(
        address accused,
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
    event SignerChanged(address staker, address signer);

    event Slashed(
        address slashed,
        bytes32 incident,
        uint256 amount,
        uint256 voted
    );

    event ParamsChanged(
        address token,
        address nft,
        uint256 threshold,
        uint256 expiration,
        address collector,
        uint256 voted,
        uint256 nonce
    );

    event VotedForParams(address user, uint256 nonce);

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
     * @param consensusLock Lock consensus votes until this block is reached.
     * @param slashCollectionAddr Address to collect slash penalties.
     * @param name Name of the EIP712 Domain.
     * @param version Version of the EIP712 Domain.
     */
    constructor(
        address tokenAddress,
        address nftAddress,
        uint256 consensusLock,
        address slashCollectionAddr,
        string memory name,
        string memory version
    ) Ownable(msg.sender) {
        _token = IERC20(tokenAddress);
        _nft = IERC721(nftAddress);
        _consensusLock = consensusLock;
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
                    keccak256(abi.encodePacked(eip712Transfer.nonces))
                )
            );
    }

    /**
     * @dev Hashes an EIP712Slash struct to its EIP712 representation.
     * @param eip712Slash The EIP712Slash struct containing slash details.
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
     * @dev Hashes an EIP712SlashKey struct to its EIP712 representation.
     * @param eip712SlashKey The EIP712SlashKey struct containing slash key details.
     * @return The EIP712 hash of the slash key.
     */
    function hash(
        EIP712SlashKey memory eip712SlashKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SLASH_KEY_TYPEHASH,
                    eip712SlashKey.accused,
                    eip712SlashKey.amount,
                    eip712SlashKey.incident
                )
            );
    }

    /**
     * @dev Hashes an EIP712SetSigner struct into its EIP712 compliant representation.
     * This is used for securely signing and verifying operations off-chain, ensuring
     * data integrity and signer authenticity for the `setSigner` function.
     * @param eip712SetSigner The struct containing the staker and new signer addresses.
     * @return The EIP712 hash of the set signer operation.
     */
    function hash(
        EIP712SetSigner memory eip712SetSigner
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SET_SIGNER_TYPEHASH,
                    eip712SetSigner.staker,
                    eip712SetSigner.signer
                )
            );
    }

    /**
     * @dev Computes the EIP-712 compliant hash of a set of parameters intended for a specific operation.
     * This operation could involve setting new contract parameters such as token address, NFT address,
     * a threshold value, a collector address, and a nonce for operation uniqueness. The hash is created
     * following the EIP-712 standard, which allows for securely signed data to be verified by the contract.
     * This function is internal and pure, meaning it doesn't alter or read the contract's state.
     * @param eip712SetParams The struct containing the parameters to be hashed. This includes token and
     * NFT addresses, a threshold value for certain operations, a collector address that may receive funds
     * or penalties, and a nonce to ensure the hash's uniqueness.
     * @return The EIP-712 compliant hash of the provided parameters, which can be used to verify signatures
     * or as a key in mappings.
     */
    function hash(
        EIP712SetParams memory eip712SetParams
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SET_PARAMS_TYPEHASH,
                    eip712SetParams.requester,
                    eip712SetParams.token,
                    eip712SetParams.nft,
                    eip712SetParams.threshold,
                    eip712SetParams.expiration,
                    eip712SetParams.collector,
                    eip712SetParams.nonce
                )
            );
    }

    /**
     * @dev Computes the EIP-712 compliant hash of a set of parameters intended for a specific operation.
     * This operation could involve setting new contract parameters such as token address, NFT address,
     * a threshold value, a collector address, and a nonce for operation uniqueness. The hash is created
     * following the EIP-712 standard, which allows for securely signed data to be verified by the contract.
     * This function is internal and pure, meaning it doesn't alter or read the contract's state.
     * @param eip712SetParamsKey The struct containing the parameters to be hashed. This includes token and
     * NFT addresses, a threshold value for certain operations, a collector address that may receive funds
     * or penalties, and a nonce to ensure the hash's uniqueness.
     * @return The EIP-712 compliant hash of the provided parameters, which can be used to verify signatures
     * or as a key in mappings.
     */
    function hash(
        EIP712SetParamsKey memory eip712SetParamsKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SET_PARAMS_KEY_TYPEHASH,
                    eip712SetParamsKey.token,
                    eip712SetParamsKey.nft,
                    eip712SetParamsKey.threshold,
                    eip712SetParamsKey.expiration,
                    eip712SetParamsKey.collector,
                    eip712SetParamsKey.nonce
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

        if (blsAddressOf(_msgSender()) == bytes20(0)) {
            revert BlsNotSet();
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
        if (evmAddressOf(blsAddress) != address(0)) {
            revert AddressInUse();
        }

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
        return
            eip712Transfer.from == signer ||
            eip712Transfer.from == signerToStaker(signer);
    }

    /**
     * @dev Verifies the authenticity of a slash request using EIP-712 typed data signing.
     * @param eip712Slash The EIP712Slash structure containing the slash request details.
     * @param signature The signature to verify the slash request.
     * @return True if the signature is valid and matches the slash request details, false otherwise.
     */
    function verify(
        EIP712Slash memory eip712Slash,
        Signature memory signature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(eip712Slash))
        );
        address signer = ECDSA.recover(
            digest,
            signature.v,
            signature.r,
            signature.s
        );
        return
            eip712Slash.accuser == signer ||
            eip712Slash.accuser == signerToStaker(signer);
    }

    /**
     * @dev Verifies the authenticity of a slash request using EIP-712 typed data signing.
     * @param eip712SetParam The EIP712Slash structure containing the slash request details.
     * @param signature The signature to verify the slash request.
     * @return True if the signature is valid and matches the slash request details, false otherwise.
     */
    function verify(
        EIP712SetParams memory eip712SetParam,
        Signature memory signature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(eip712SetParam))
        );
        address signer = ECDSA.recover(
            digest,
            signature.v,
            signature.r,
            signature.s
        );
        return
            eip712SetParam.requester == signer ||
            eip712SetParam.requester == signerToStaker(signer);
    }

    /**
     * @dev Verifies the signatures of both the staker and the signer for a `setSigner`
     * operation, ensuring both parties agree to the change. This method uses EIP-712
     * signature standards for secure verification of off-chain signed data.
     * @param eip712SetSigner Struct containing the addresses involved in the operation.
     * @param stakerSignature Signature of the staker agreeing to the operation.
     * @param signerSignature Signature of the signer being set, agreeing to their role.
     * @return True if both signatures are valid and correspond to the staker and signer.
     */
    function verify(
        EIP712SetSigner memory eip712SetSigner,
        Signature memory stakerSignature,
        Signature memory signerSignature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hash(eip712SetSigner)
            )
        );
        address primarySigner = ECDSA.recover(
            digest,
            stakerSignature.v,
            stakerSignature.r,
            stakerSignature.s
        );
        address secondarySigner = ECDSA.recover(
            digest,
            signerSignature.v,
            signerSignature.r,
            signerSignature.s
        );
        return
            primarySigner == eip712SetSigner.staker &&
            secondarySigner == eip712SetSigner.signer;
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
            _totalVotingPower -= eip712Transfer.amount;
            _token.safeTransfer(eip712Transfer.to, eip712Transfer.amount);
        }
    }

    /**
     * @dev Allows a staker to securely designate another address as their signer
     * for signing operations, using EIP-712 signatures for verification. This can
     * delegate signing authority while retaining control over staked assets.
     * @param eip712SetSigner The struct containing the staker and signer addresses.
     * @param stakerSignature The staker's signature verifying their agreement.
     * @param signerSignature The signer's signature verifying their acceptance.
     */
    function setSigner(
        EIP712SetSigner memory eip712SetSigner,
        Signature memory stakerSignature,
        Signature memory signerSignature
    ) external {
        bool valid = verify(eip712SetSigner, stakerSignature, signerSignature);

        if (!valid) {
            revert Forbidden();
        }

        _signerToStaker[eip712SetSigner.signer] = eip712SetSigner.staker;
        _stakerToSigner[eip712SetSigner.staker] = eip712SetSigner.signer;

        emit SignerChanged(eip712SetSigner.staker, eip712SetSigner.signer);
    }

    /**
     * @dev Returns the staker address associated with a given signer address.
     * This can be used to look up the controlling staker of a signer.
     * @param signer The address of the signer.
     * @return The address of the staker who set the signer.
     */
    function signerToStaker(address signer) public view returns (address) {
        return _signerToStaker[signer];
    }

    /**
     * @dev Returns the signer address associated with a given staker address.
     * This function allows querying who has been designated as the signer for a staker.
     * @param staker The address of the staker.
     * @return The address of the signer set by the staker.
     */
    function stakerToSigner(address staker) external view returns (address) {
        return _stakerToSigner[staker];
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
        if (block.number <= _consensusLock) {
            revert Forbidden();
        }

        if (eip712Slashes.length != signatures.length) {
            revert LengthMismatch();
        }

        uint256 threshold = (_totalVotingPower * _consensusThreshold) / 100;

        for (uint i = 0; i < eip712Slashes.length; i++) {
            EIP712Slash memory eip712Slash = eip712Slashes[i];

            EIP712SlashKey memory slashKey = EIP712SlashKey(
                eip712Slash.accused,
                eip712Slash.amount,
                eip712Slash.incident
            );

            bytes32 eipHash = hash(slashKey);

            if (_firstReported[eipHash] == 0) {
                _firstReported[eipHash] = block.timestamp;
            }

            uint256 expires = _firstReported[eipHash] + _votingTopicExpiration;

            if (block.timestamp > expires) {
                revert TopicExpired(i);
            }

            Stake memory userStake = _stakes[eip712Slash.accuser];

            if (userStake.amount == 0) {
                revert VotingPowerZero(i);
            }

            if (userStake.unlock <= expires) {
                revert StakeExpiresBeforeVote(i);
            }

            Slash storage slashData = _slashes[eipHash];

            if (slashData.accusers[eip712Slash.accuser]) {
                revert AlreadyAccused(i);
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712Slash, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            slashData.info.amount = eip712Slash.amount;
            slashData.info.accused = eip712Slash.accused;
            slashData.info.incident = eip712Slash.incident;
            slashData.info.voted += userStake.amount;
            slashData.accusers[eip712Slash.accuser] = true;

            emit Accused(
                eip712Slash.accused,
                eip712Slash.accuser,
                eip712Slash.amount,
                slashData.info.voted,
                eip712Slash.incident
            );

            if (_incidentTracker[eip712Slash.incident]) {
                continue;
            }

            if (slashData.info.voted >= threshold) {
                _incidentTracker[eip712Slash.incident] = true;
                slashData.info.slashed = true;

                _stakes[eip712Slash.accused].amount -= slashData.info.amount;
                _totalVotingPower -= slashData.info.amount;

                _token.safeTransfer(
                    _slashCollectionAddr,
                    slashData.info.amount
                );

                emit Slashed(
                    slashData.info.accused,
                    slashData.info.incident,
                    slashData.info.amount,
                    slashData.info.voted
                );
            }
        }
    }

    /**
     * @dev Retrieves detailed information about a specific slash incident identified
     * by a unique EIP712SlashKey. This function computes the hash of the key to look up
     * the slash incident and returns its associated data.
     * @param key The EIP712SlashKey struct containing the details needed to identify
     * the slash incident.
     * @return SlashInfo A struct containing detailed information about the slash incident.
     */
    function getSlashData(
        EIP712SlashKey memory key
    ) external view returns (SlashInfo memory) {
        bytes32 eipHash = hash(key);
        Slash storage slashData = _slashes[eipHash];
        return slashData.info;
    }

    /**
     * @dev Checks whether a given address has participated as an accuser in a
     * specific slash incident. This is determined by looking up the slash incident
     * using the hash of the provided EIP712SlashKey and checking if the slasher's
     * address is marked as an accuser.
     * @param key The EIP712SlashKey struct containing the details needed to identify
     * the slash incident.
     * @param slasher The address of the potential accuser to check for participation
     * in the slash incident.
     * @return A boolean indicating whether the specified address has accused in the
     * slash incident.
     */
    function getHasSlashed(
        EIP712SlashKey memory key,
        address slasher
    ) external view returns (bool) {
        bytes32 eipHash = hash(key);
        Slash storage slashData = _slashes[eipHash];
        return slashData.accusers[slasher];
    }

    /**
     * @dev Returns the current threshold for slashing to occur. This
     * represents the minimum percentage of total voting power that must agree
     * on a slash for it to be executed.
     * @return The slashing threshold as a percentage of total voting power.
     */
    function getConsensusThreshold() external view returns (uint256) {
        return _consensusThreshold;
    }

    /**
     * @dev Allows a batch update of contract parameters through a consensus mechanism. This function
     * requires a matching signature for each set of parameters to validate each requester's intent.
     * It enforces a consensus threshold based on the total voting power and prevents execution
     * before a specified block number (_consensusLock) for security.
     * @param eip712SetParams An array of EIP712SetParams structs, each containing a proposed set
     * of parameter updates.
     * @param signatures An array of signatures corresponding to each set of parameters, used to
     * verify the authenticity of the requests.
     * @notice Reverts if called before the consensus lock period ends, if the length of parameters
     * and signatures arrays do not match, if any signature is invalid, or if the voting power
     * threshold for consensus is not met.
     */
    function setParams(
        EIP712SetParams[] memory eip712SetParams,
        Signature[] memory signatures
    ) external {
        if (block.number <= _consensusLock) {
            revert Forbidden();
        }

        if (eip712SetParams.length != signatures.length) {
            revert LengthMismatch();
        }

        uint256 threshold = (_totalVotingPower * _consensusThreshold) / 100;

        for (uint i = 0; i < eip712SetParams.length; i++) {
            EIP712SetParams memory eip712SetParam = eip712SetParams[i];

            EIP712SetParamsKey memory key = EIP712SetParamsKey(
                eip712SetParam.token,
                eip712SetParam.nft,
                eip712SetParam.threshold,
                eip712SetParam.expiration,
                eip712SetParam.collector,
                eip712SetParam.nonce
            );

            bytes32 eipHash = hash(key);

            if (_firstReported[eipHash] == 0) {
                _firstReported[eipHash] = block.timestamp;
            }

            uint256 expires = _firstReported[eipHash] + _votingTopicExpiration;

            if (block.timestamp > expires) {
                revert TopicExpired(i);
            }

            Stake memory userStake = _stakes[eip712SetParam.requester];

            if (userStake.amount == 0) {
                revert VotingPowerZero(i);
            }

            if (userStake.unlock <= expires) {
                revert StakeExpiresBeforeVote(i);
            }

            Params storage setParamsData = _setParams[eipHash];

            if (setParamsData.requesters[eip712SetParam.requester]) {
                revert AlreadyVoted(i);
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712SetParam, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            setParamsData.requesters[eip712SetParam.requester] = true;

            setParamsData.info.voted += userStake.amount;
            setParamsData.info.token = eip712SetParam.token;
            setParamsData.info.nft = eip712SetParam.nft;
            setParamsData.info.threshold = eip712SetParam.threshold;
            setParamsData.info.expiration = eip712SetParam.expiration;
            setParamsData.info.collector = eip712SetParam.collector;
            setParamsData.info.nonce = eip712SetParam.nonce;

            emit VotedForParams(eip712SetParam.requester, eip712SetParam.nonce);

            if (_setParamsTracker[eip712SetParam.nonce]) {
                continue;
            }

            if (setParamsData.info.voted >= threshold) {
                _setParamsTracker[eip712SetParam.nonce] = true;

                _token = IERC20(setParamsData.info.token);
                _nft = IERC721(setParamsData.info.nft);
                _consensusThreshold = setParamsData.info.threshold;
                _slashCollectionAddr = setParamsData.info.collector;
                _votingTopicExpiration = setParamsData.info.expiration;

                emit ParamsChanged(
                    setParamsData.info.token,
                    setParamsData.info.nft,
                    setParamsData.info.threshold,
                    setParamsData.info.expiration,
                    setParamsData.info.collector,
                    setParamsData.info.voted,
                    setParamsData.info.nonce
                );
            }
        }
    }

    /**
     * @dev Retrieves the detailed information about a set of parameters identified by a hash
     * of the EIP712SetParams struct. This can include the token, NFT addresses, threshold,
     * collector address, and the nonce used for the request.
     * @param key The EIP712SetParams struct containing details to identify the parameters.
     * @return ParamsInfo The detailed information of the requested set parameters operation.
     */
    function getSetParamsData(
        EIP712SetParamsKey memory key
    ) external view returns (ParamsInfo memory) {
        bytes32 eipHash = hash(key);
        Params storage setParamsData = _setParams[eipHash];
        return setParamsData.info;
    }

    /**
     * @dev Retrieves the current contract parameters, including the token and NFT addresses,
     * the consensus threshold, the voting topic expiration, and the collector address for
     * slash penalties. This function returns the current state of the contract's parameters.
     * @return ParamsInfo A struct containing the current contract parameters.
     */
    function getParams() external view returns (ParamsInfo memory) {
        return
            ParamsInfo(
                address(_token),
                address(_nft),
                _consensusThreshold,
                _votingTopicExpiration,
                _slashCollectionAddr,
                0,
                0,
                true
            );
    }

    /**
     * @dev Checks if a specific address has already requested a set of parameter updates. This
     * is useful for verifying participation in the consensus process for a parameter update.
     * @param key The EIP712SetParams struct containing the details to identify the parameter
     * update request.
     * @param requester The address of the potential requester to check.
     * @return A boolean indicating whether the address has already requested the set of parameters.
     */
    function getHasRequestedSetParams(
        EIP712SetParamsKey memory key,
        address requester
    ) external view returns (bool) {
        bytes32 eipHash = hash(key);
        Params storage setParamsData = _setParams[eipHash];
        return setParamsData.requesters[requester];
    }

    /**
     * @dev Returns the total voting power represented by the sum of all staked tokens.
     * Voting power is used in governance decisions, including the slashing process,
     * where it determines the weight of a participant's vote. This function provides
     * the aggregate voting power at the current state.
     * @return The total voting power from all staked tokens.
     */
    function getTotalVotingPower() external view returns (uint256) {
        return _totalVotingPower;
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
