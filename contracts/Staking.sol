//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Tracker.sol";

// TODO: Should there be a max voting power?
// TODO: Add NFT support for the consensus mechanism

/**
 * @title Unchained Staking
 * @notice This contract allows users to stake ERC20 tokens and ERC721 NFTs,
 * offering functionalities to stake, unstake, extend stakes, and manage
 * transfering in case of misbehavior. It implements an EIP-712 domain for
 * secure off-chain signature verifications, enabling decentralized governance
 * actions like voting or transfering without on-chain transactions for each
 * vote.
 *
 * The contract includes a transfering mechanism where staked tokens can be
 * transfered (removed from the stake) if the majority of voting power agrees on
 * a misbehavior or a transfer request. The contract also allows users to set
 * their BLS (Boneh-Lynn-Shacham) address for secure off-chain signing and
 * verification.
 *
 * The contract also includes a consensus mechanism where users can set
 * parameters for the contract, such as the token address, NFT address, a
 * threshold value for certain operations, and an expiration time for voting on
 * proposals. The consensus mechanism requires a majority vote to approve
 * changes to the contract's parameters.
 *
 * The contract also includes a mechanism to set the price of NFTs, which can
 * be used to govern the price of NFTs in the system. This mechanism requires
 * a majority vote to approve changes to the price of NFTs.
 *
 * The contract also includes a mechanism to set a signer for a staker, allowing
 * stakers to delegate signing authority to another address for secure off-chain
 * signing and verification.
 */
contract UnchainedStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Interfaces for the ERC20 token, ERC721 NFT, and NFT tracker
     */
    IERC20 private _token;
    IERC721 private _nft;
    INFTTracker private _nftTracker;

    /**
     * @dev EIP712 domain struct for secure off-chain signature verification.
     * @param name The name of the domain.
     * @param version The version of the domain.
     * @param chainId The chain ID of the domain.
     * @param verifyingContract The address of the verifying contract.
     */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /**
     * @dev Struct containing the details of a signature for secure off-chain
     * verification.
     * @param v The recovery ID.
     * @param r The R value.
     * @param s The S value.
     */
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @dev Struct containing the details of a stake, including the amount
     * staked, the unlock time, and the NFTs staked.
     * @param amount The amount of tokens staked.
     * @param unlock The unlock time for the stake.
     * @param nftIds An array of NFT IDs staked.
     * @param consumable A flag indicating if the stake is consumable.
     */
    struct Stake {
        uint256 amount;
        uint256 unlock;
        uint256[] nftIds;
        bool consumable;
    }

    /**
     * @dev Struct containing the details of a transfer request, including the
     * sender, recipient, amount, NFTs, nonces, and voting details.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens transferred.
     * @param nftIds An array of NFT IDs transferred.
     * @param voted The total voting power that voted.
     * @param accepted A flag indicating if the transfer request was accepted.
     * @param nonces An array of nonces used in the transfer.
     */
    struct TransferInfo {
        address from;
        address to;
        uint256 amount;
        uint256[] nftIds;
        uint256 voted;
        bool accepted;
        uint256[] nonces;
    }

    /**
     * @dev Struct containing the details of a transfer request, including the
     * transfer details and the signers who have voted on the request.
     * @param info The transfer details.
     * @param signers A mapping of signers who have voted on the request.
     */
    struct TransferRequest {
        TransferInfo info;
        mapping(address => bool) signers;
    }

    /**
     * @dev Struct containing the details of a parameter change consensus
     * proposal, including the token address, NFT address, NFT tracker address,
     * threshold value, expiration time, voting details, and nonce.
     * @param token The new token address.
     * @param nft The new NFT address.
     * @param nftTracker The new NFT tracker address.
     * @param threshold The new threshold value.
     * @param expiration The new expiration time.
     * @param voted The total voting power that voted.
     * @param nonce The nonce of the proposal.
     * @param accepted A flag indicating if the proposal was accepted.
     */
    struct ParamsInfo {
        address token;
        address nft;
        address nftTracker;
        uint256 threshold;
        uint256 expiration;
        uint256 voted;
        uint256 nonce;
        bool accepted;
    }

    /**
     * @dev Struct containing the details of a parameter change consensus
     * proposal, including the proposal details and the signers who have voted
     * on the proposal.
     * @param info The proposal details.
     * @param requesters A mapping of signers who have voted on the proposal.
     */
    struct Params {
        ParamsInfo info;
        mapping(address => bool) requesters;
    }

    /**
     * @dev Struct containing the details of an NFT price change consensus
     * proposal, including the NFT ID, price, voting details, and nonce.
     * @param nftId The NFT ID.
     * @param price The new price to set.
     * @param voted The total voting power that voted.
     * @param accepted A flag indicating if the proposal was accepted.
     */
    struct NftPriceInfo {
        uint256 nftId;
        uint256 price;
        uint256 voted;
        bool accepted;
    }

    /**
     * @dev Struct containing the details of an NFT price change consensus
     * proposal, including the proposal details and the signers who have voted
     * on the proposal.
     * @param info The proposal details.
     * @param requesters A mapping of signers who have voted on the proposal.
     */
    struct NftPrice {
        NftPriceInfo info;
        mapping(address => bool) requesters;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying transfer requests
     * off-chain. This struct includes the signer, sender, recipient, amount,
     * NFTs, and nonces involved in the transfer.
     * @param signer The address of the signer.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens transferred.
     * @param nftIds An array of NFT IDs transferred.
     * @param nonces An array of nonces used in the transfer.
     */
    struct EIP712Transfer {
        address signer;
        address from;
        address to;
        uint256 amount;
        uint256[] nftIds;
        uint256[] nonces;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying transfer requests
     * off-chain. This struct includes the sender, recipient, amount, and nonces
     * involved in the transfer. This struct is used as a key for the transfer
     * request mapping.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens transferred.
     * @param nftIds An array of NFT IDs transferred.
     * @param nonces An array of nonces used in the transfer.
     */
    struct EIP712TransferKey {
        address from;
        address to;
        uint256 amount;
        uint256[] nftIds;
        uint256[] nonces;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying parameter set
     * consensus requests off-chain. This struct includes the staker and signer
     * addresses involved in the operation.
     * @param requester The address of the requester.
     * @param token The address of the token.
     * @param nft The address of the NFT.
     * @param nftTracker The address of the NFT tracker.
     * @param threshold The threshold value for the operation.
     * @param expiration The expiration time for the operation.
     * @param nonce The nonce of the operation.
     */
    struct EIP712SetParams {
        address requester;
        address token;
        address nft;
        address nftTracker;
        uint256 threshold;
        uint256 expiration;
        uint256 nonce;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying parameter set
     * consensus requests off-chain. This struct includes the token and NFT
     * addresses, threshold value, expiration time, and nonce involved in the
     * operation. This struct is used as a key for the parameter set mapping.
     * @param token The address of the token.
     * @param nft The address of the NFT.
     * @param nftTracker The address of the NFT tracker.
     * @param threshold The threshold value for the operation.
     * @param expiration The expiration time for the operation.
     * @param nonce The nonce of the operation.
     */
    struct EIP712SetParamsKey {
        address token;
        address nft;
        address nftTracker;
        uint256 threshold;
        uint256 expiration;
        uint256 nonce;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying NFT price set
     * consensus requests off-chain. This struct includes the requester, NFT ID,
     * price, and nonce involved in the operation.
     * @param requester The address of the requester.
     * @param nftId The NFT ID.
     * @param price The new price to set.
     * @param nonce The nonce of the operation.
     */
    struct EIP712SetNftPrice {
        address requester;
        uint256 nftId;
        uint256 price;
        uint256 nonce;
    }

    /**
     * @dev EIP712 struct for securely signing and verifying NFT price set
     * consensus requests off-chain. This struct includes the NFT ID, price, and
     * nonce involved in the operation. This struct is used as a key for the NFT
     * price mapping.
     * @param nftId The NFT ID.
     * @param price The new price to set.
     * @param nonce The nonce of the operation.
     */
    struct EIP712SetNftPriceKey {
        uint256 nftId;
        uint256 price;
        uint256 nonce;
    }

    /**
     * @dev EIP712 struct for securely signing, verifying, and assigning a new
     * signer to a staker off-chain. This struct includes the staker and signer
     * addresses involved in the operation.
     * @param staker The address of the staker.
     * @param signer The address of the signer.
     */
    struct EIP712SetSigner {
        address staker;
        address signer;
    }

    /**
     * @dev Error messages for the contract.
     */
    error WrongNFT();
    error AmountZero();
    error DurationZero();
    error NotUnlocked();
    error AlreadyStaked();
    error AddressInUse();
    error BlsNotSet();
    error StakeZero();
    error Forbidden();
    error NonceUsed(uint256 index, uint256 nonce);
    error LengthMismatch();
    error InvalidSignature(uint256 index);
    error VotingPowerZero(uint256 index);
    error TopicExpired(uint256 index);
    error StakeExpiresBeforeVote(uint256 index);

    /**
     * @dev Mapping of nonces for each address and transfer request.
     */
    mapping(address => mapping(uint256 => bool)) private _nonces;

    /**
     * @dev Mapping of nft prices for each NFT ID.
     */
    mapping(uint256 => uint256) _cachedNftPrices;

    /**
     * @dev Mapping of transfer requests to their associated details.
     */
    bytes32 immutable DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant EIP712_TRANSFER_TYPEHASH =
        keccak256(
            "EIP712Transfer(address signer,address from,address to,uint256 amount,uint256[] nftIds,uint256[] nonces)"
        );

    bytes32 constant EIP712_TRANSFER_KEY_TYPEHASH =
        keccak256(
            "EIP712TransferKey(address from,address to,uint256 amount,uint256[] nonces)"
        );

    bytes32 constant EIP712_SET_SIGNER_TYPEHASH =
        keccak256("EIP712SetSigner(address staker,address signer)");

    bytes32 constant EIP712_SET_PARAMS_TYPEHASH =
        keccak256(
            "EIP712SetParams(address requester,address token,address nft,address nftTracker,uint256 threshold,uint256 expiration,uint256 nonce)"
        );

    bytes32 constant EIP712_SET_PARAMS_KEY_TYPEHASH =
        keccak256(
            "EIP712SetParamsKey(address token,address nft,address nftTracker,uint256 threshold,uint256 expiration,uint256 nonce)"
        );

    bytes32 constant EIP712_SET_NFT_PRICE_TYPEHASH =
        keccak256(
            "EIP712SetNftPrice(address requester,uint256 nftId,uint256 price,uint256 nonce)"
        );

    bytes32 constant EIP712_SET_NFT_PRICE_KEY_TYPEHASH =
        keccak256(
            "EIP712SetNftPriceKey(uint256 nftId,uint256 price,uint256 nonce)"
        );

    /**
     * @dev Consensus mechanism variables and parameters.
     * These variables are used to control the consensus mechanism for setting
     * contract parameters and NFT prices.
     */
    uint256 private _consensusLock;
    uint256 private _consensusThreshold = 51;
    uint256 private _votingTopicExpiration = 1 days;
    uint256 private _totalVotingPower;

    /**
     * @dev Variables to track the total amount of tokens moved to the Unchained
     * network to be managed by the consensus mechanism.
     */
    uint256 private _lockedInUnchained;

    /**
     * @dev Mapping of stakers to their associated stakes.
     */
    mapping(address => Stake) private _stakes;

    /**
     * @dev Mapping of transfer requests to their associated details.
     */
    mapping(bytes32 => TransferRequest) private _transfers;

    /**
     * @dev Mapping of stakers to their Unchained BLS addresses.
     */
    mapping(bytes20 => address) private _blsToAddress;
    mapping(address => bytes20) private _addressToBls;

    /**
     * @dev Mapping of stakers to their associated signers.
     */
    mapping(address => address) private _signerToStaker;
    mapping(address => address) private _stakerToSigner;

    /**
     * @dev Mapping of set parameter consensus requests to their associated
     * details.
     */
    mapping(bytes32 => Params) private _setParams;

    /**
     * @dev Mapping of set NFT price consensus requests to their associated
     * details.
     */
    mapping(bytes32 => NftPrice) private _setNftPrice;

    /**
     * @dev Mapping of consensus votes for each topic to their associated
     * first reported time. This is used to track the expiration of topics.
     */
    mapping(bytes32 => uint256) private _firstReported;

    /**
     * @dev Variable to control the acceptance of NFTs in the contract to
     * prevent accidental transfers.
     */
    bool private _acceptNft;

    /**
     * @dev Event emitted when a user stakes tokens and NFTs.
     * @param user The address of the user who staked the tokens and NFTs.
     * @param unlock The unlock time for the stake.
     * @param amount The amount of tokens staked.
     * @param nftIds An array of NFT IDs staked.
     */
    event Staked(
        address indexed user,
        uint256 unlock,
        uint256 amount,
        uint256[] nftIds
    );

    /**
     * @dev Event emitted when a user unstakes tokens and NFTs.
     * @param user The address of the user who unstaked the tokens and NFTs.
     * @param amount The amount of tokens unstaked.
     * @param nftIds An array of NFT IDs unstaked.
     */
    event UnStaked(address indexed user, uint256 amount, uint256[] nftIds);

    /**
     * @dev Event emitted when a user extends the duration of their stake.
     * @param user The address of the user who extended the stake.
     * @param unlock The new unlock time for the stake.
     */
    event Extended(address indexed user, uint256 unlock);

    /**
     * @dev Event emitted when a user increases their stake amount and NFTs.
     * @param user The address of the user who increased the stake.
     * @param amount The new amount of tokens staked.
     * @param nftIds An array of additional NFT IDs staked.
     */
    event StakeIncreased(
        address indexed user,
        uint256 amount,
        uint256[] nftIds
    );

    /**
     * @dev Event emitted when a user sets their BLS address.
     * @param user The address of the user who set their BLS address.
     * @param from The previous BLS address.
     * @param to The new BLS address.
     */
    event BlsAddressChanged(
        address indexed user,
        bytes32 indexed from,
        bytes32 indexed to
    );

    /**
     * @dev Event emitted when a user sets a new signer.
     * @param staker The address of the staker who set the new signer.
     * @param signer The address of the new signer.
     */
    event SignerChanged(address indexed staker, address indexed signer);

    /**
     * @dev Event emitted when a transfer request is accepted.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens transferred.
     * @param nftIds An array of NFT IDs transferred.
     * @param nonces An array of nonces used in the transfer.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256[] nftIds,
        uint256[] nonces
    );

    /**
     * @dev Event emitted when a user moves their tokens to the Unchained
     * contract. These tokens are then managed by the Unchained network
     * consensus mechanism.
     * @param from The address of the user who moved their tokens.
     * @param amount The amount of tokens moved.
     */
    event TransferToUnchained(address indexed from, uint256 amount);

    /**
     * @dev Event emitted when a parameter change consensus proposal is
     * accepted.
     * @param token The new token address.
     * @param nft The new NFT address.
     * @param nftTracker The new NFT tracker address.
     * @param threshold The new threshold value.
     * @param expiration The new expiration time.
     * @param voted The total voting power that voted.
     * @param nonce The nonce of the proposal.
     */
    event ParamsChanged(
        address token,
        address nft,
        address nftTracker,
        uint256 threshold,
        uint256 expiration,
        uint256 voted,
        uint256 nonce
    );

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
     * @param name Name of the EIP712 Domain.
     * @param version Version of the EIP712 Domain.
     */
    constructor(
        address tokenAddress,
        address nftAddress,
        address nftTrackerAddress,
        uint256 consensusLock,
        string memory name,
        string memory version
    ) Ownable(msg.sender) {
        _token = IERC20(tokenAddress);
        _nft = IERC721(nftAddress);
        _nftTracker = INFTTracker(nftTrackerAddress);
        _consensusLock = consensusLock;
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
     * @dev Ensures that this contract can receive NFTs safely. Reverts if the
     * NFT is not the expected one.
     * @param {} The address which called the `safeTransferFrom` function on the
     * NFT contract.
     * @param {} The address which previously owned the token.
     * @param {} The NFT identifier which is being transferred.
     * @param {} Additional data with no specified format sent along with the
     * call.
     * @return The selector to confirm the contract implements the
     * ERC721Received interface.
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
     * @param eip712Transfer The EIP712Transfer struct containing transfer
     * details.
     * @return The EIP712 hash of the transfer.
     */
    function hash(
        EIP712Transfer memory eip712Transfer
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_TRANSFER_TYPEHASH,
                    eip712Transfer.signer,
                    eip712Transfer.from,
                    eip712Transfer.to,
                    eip712Transfer.amount,
                    keccak256(abi.encodePacked(eip712Transfer.nftIds)),
                    keccak256(abi.encodePacked(eip712Transfer.nonces))
                )
            );
    }

    /**
     * @dev Hashes an EIP712TransferKey struct to its EIP712 representation.
     * @param key The EIP712TransferKey struct containing the transfer details.
     * @return The EIP712 hash of the transfer.
     */
    function hash(
        EIP712TransferKey memory key
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_TRANSFER_TYPEHASH,
                    key.from,
                    key.to,
                    key.amount,
                    keccak256(abi.encodePacked(key.nftIds)),
                    keccak256(abi.encodePacked(key.nonces))
                )
            );
    }

    /**
     * @dev Hashes an EIP712SetSigner struct into its EIP712 compliant
     * representation. This is used for securely signing and verifying
     * operations off-chain, ensuring data integrity and signer authenticity for
     * the `setSigner` function.
     * @param eip712SetSigner The struct containing the staker and new signer
     * addresses.
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
     * @dev Hashes an EIP712SetParams struct into its EIP712 compliant
     * representation. This is used for securely signing and verifying
     * operations off-chain, ensuring data integrity and signer authenticity for
     * the `setParams` function.
     * @param eip712SetParams The struct containing the parameters to be hashed.
     * This includes token and NFT addresses, a threshold value for certain
     * operations, and a nonce to ensure the hash's uniqueness.
     * @return The EIP712 hash of the provided parameters, which can be used to
     * verify signatures or as a key in mappings.
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
                    eip712SetParams.nftTracker,
                    eip712SetParams.threshold,
                    eip712SetParams.expiration,
                    eip712SetParams.nonce
                )
            );
    }

    /**
     * @dev Computes the EIP-712 compliant hash of a set of parameters intended
     * for a specific operation. This operation could involve setting new
     * contract parameters such as token address, NFT address, a threshold
     * value, and a nonce for operation uniqueness. The hash is created
     * following the EIP-712 standard, which allows for securely signed data to
     * be verified by the contract. This function is internal and pure, meaning
     * it doesn't alter or read the contract's state.
     * @param eip712SetParamsKey The struct containing the parameters to be
     * hashed. This includes token and NFT addresses, a threshold value for
     * certain operations, and a nonce to ensure the hash's uniqueness.
     * @return The EIP-712 compliant hash of the provided parameters, which can
     * be used to verify signatures or as a key in mappings.
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
                    eip712SetParamsKey.nftTracker,
                    eip712SetParamsKey.threshold,
                    eip712SetParamsKey.expiration,
                    eip712SetParamsKey.nonce
                )
            );
    }

    /**
     * @dev Hashes an EIP712SetNftPrice struct into its EIP712 compliant
     * representation. This is used for securely signing and verifying
     * operations off-chain, ensuring data integrity and signer authenticity for
     * the `setNftPrice` function.
     * @param eip712SetNftPrice The struct containing the parameters to be
     * hashed. This includes the NFT ID, the new price to set, and a nonce to
     * ensure the hash's uniqueness.
     * @return The EIP712 hash of the set NFT price operation.
     */
    function hash(
        EIP712SetNftPrice memory eip712SetNftPrice
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SET_NFT_PRICE_TYPEHASH,
                    eip712SetNftPrice.requester,
                    eip712SetNftPrice.nftId,
                    eip712SetNftPrice.price,
                    eip712SetNftPrice.nonce
                )
            );
    }

    /**
     * @dev Computes the EIP-712 compliant hash of a set of parameters intended
     * for a specific operation. This operation could involve setting a new
     * price for an NFT, which is a governance action that requires secure
     * off-chain signing. The hash is created following the EIP-712 standard,
     * which allows for securely signed data to be verified by the contract.
     * This function is internal and pure, meaning it doesn't alter or read the
     * contract's state.
     * @param eip712SetNftPriceKey The struct containing the parameters to be
     * hashed. This includes the NFT ID, the new price to set, and a nonce to
     * ensure the hash's uniqueness.
     * @return The EIP-712 compliant hash of the provided parameters, which can
     * be used to verify signatures or as a key in mappings.
     */
    function hash(
        EIP712SetNftPriceKey memory eip712SetNftPriceKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_SET_NFT_PRICE_KEY_TYPEHASH,
                    eip712SetNftPriceKey.nftId,
                    eip712SetNftPriceKey.price,
                    eip712SetNftPriceKey.nonce
                )
            );
    }

    /**
     * @dev Called by a user to stake their tokens along with NFTs if desired.
     * @param duration The duration for which the tokens and NFTs are staked.
     * @param amount The amount of tokens to stake.
     * @param nftIds An array of NFT IDs to stake along with the tokens.
     */
    function stake(
        uint256 duration,
        uint256 amount,
        uint256[] memory nftIds
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

        _stakes[_msgSender()].unlock = block.timestamp + duration;

        for (uint256 i = 0; i < nftIds.length; i++) {
            _stakes[_msgSender()].nftIds.push(nftIds[i]);
            _nft.safeTransferFrom(_msgSender(), address(this), nftIds[i], "");
        }

        _totalVotingPower += nftIds.length;

        emit Staked(_msgSender(), _stakes[_msgSender()].unlock, amount, nftIds);
    }

    /**
     * @dev Called by a user to extend the duration of their existing stake.
     * @param duration The additional duration to add to the current stake's
     * unlock time.
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
     * @dev Called by a user to increase their stake amount and optionally add
     * more NFTs to the stake.
     * @param amount The additional amount of tokens to add to the existing
     * stake.
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

        _totalVotingPower += nftIds.length;

        emit StakeIncreased(_msgSender(), _stakes[_msgSender()].amount, nftIds);
    }

    /**
     * @dev Called by a user to unstake their tokens and NFTs once the stake
     * duration has ended.
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
     * @dev Allows a user to set or update their BLS (Boneh-Lynn-Shacham)
     * address.
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
    function getStake(bytes20 bls) public view returns (Stake memory) {
        return _stakes[evmAddressOf(bls)];
    }

    /**
     * @dev Retrieves the stake information associated with a given EVM address.
     * @param evm The EVM address to query the stake information.
     * @return The stake information associated with the given EVM address.
     */
    function getStake(address evm) public view returns (Stake memory) {
        return _stakes[evm];
    }

    /**
     * @dev Verifies the authenticity of a transfer request using EIP-712 typed
     * data signing.
     * @param eip712Transfer The EIP712Transfer structure containing the
     * transfer request details.
     * @param signature The signature to verify the transfer request.
     * @return True if the signature is valid and matches the transfer request
     * details, false otherwise.
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
            eip712Transfer.signer == signer ||
            eip712Transfer.signer == signerToStaker(signer);
    }

    /**
     * @dev Verifies the authenticity of a setParams request using EIP-712 typed
     * data signing.
     * @param eip712SetParam The EIP712SetParams structure containing the
     * transfer request details.
     * @param signature The signature to verify the transfer request.
     * @return True if the signature is valid and matches the transfer request
     * details, false otherwise.
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
     * @dev Verifies the authenticity of a setNftPrice request using EIP-712 typed
     * data signing.
     * @param eip712SetNftPrice The EIP712SetNftPrice structure containing the
     * transfer request details.
     * @param signature The signature to verify the transfer request.
     * @return True if the signature is valid and matches the transfer request
     * details, false otherwise.
     */
    function verify(
        EIP712SetNftPrice memory eip712SetNftPrice,
        Signature memory signature
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hash(eip712SetNftPrice)
            )
        );
        address signer = ECDSA.recover(
            digest,
            signature.v,
            signature.r,
            signature.s
        );
        return
            eip712SetNftPrice.requester == signer ||
            eip712SetNftPrice.requester == signerToStaker(signer);
    }

    /**
     * @dev Verifies the signatures of both the staker and the signer for a
     * `setSigner` operation, ensuring both parties agree to the change. This
     * method uses EIP-712 signature standards for secure verification of
     * off-chain signed data.
     * @param eip712SetSigner Struct containing the addresses involved in the
     * operation.
     * @param stakerSignature Signature of the staker agreeing to the operation.
     * @param signerSignature Signature of the signer being set, agreeing to
     * their role.
     * @return True if both signatures are valid and correspond to the staker
     * and signer.
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
     * @dev Allows a staker to securely designate another address as their
     * signer for signing operations, using EIP-712 signatures for verification.
     * This can delegate signing authority while retaining control over staked
     * assets.
     * @param eip712SetSigner The struct containing the staker and signer
     * addresses.
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
     * This function allows querying who has been designated as the signer for a
     * staker.
     * @param staker The address of the staker.
     * @return The address of the signer set by the staker.
     */
    function stakerToSigner(address staker) external view returns (address) {
        return _stakerToSigner[staker];
    }

    function burnTransferNonces(
        uint256 index,
        address to,
        uint256[] memory nonces
    ) internal onlyOwner {
        for (uint256 n = 0; n < nonces.length; n++) {
            if (_nonces[to][nonces[n]]) {
                revert NonceUsed(index, nonces[n]);
            }
            _nonces[to][nonces[n]] = true;
        }
    }

    /**
     * @dev Moves tokens from a user to the Unchained contract. These tokens are
     * then managed by the Unchained network consensus mechanism.
     * @param amount The amount of tokens to move.
     */
    function transferToUnchained(uint256 amount) public {
        if (amount == 0) {
            revert AmountZero();
        }

        if (blsAddressOf(_msgSender()) == bytes20(0)) {
            revert BlsNotSet();
        }

        _token.safeTransferFrom(_msgSender(), address(this), amount);
        _lockedInUnchained += amount;
        emit TransferToUnchained(_msgSender(), amount);
    }

    /**
     * @dev Retrieves the total amount of tokens locked in the Unchained
     * network.
     * @return The total amount of tokens locked in the Unchained network.
     */
    function getTotalLockedInUnchained() public view returns (uint256) {
        return _lockedInUnchained;
    }

    /**
     * @dev Processes a batch of transfer requests against stakers for
     * misbehaviour, validated by signatures. Each transfer request decreases
     * the stake of the accused if the collective voting power of accusers
     * exceeds a threshold.
     * @param eip712Transfers An array of EIP712Transfer structures containing
     * details of each transfer request.
     * @param signatures An array of signatures corresponding to each transfer
     * request for validation.
     */
    function transfer(
        EIP712Transfer[] memory eip712Transfers,
        Signature[] memory signatures
    ) external nonReentrant {
        if (block.number <= _consensusLock) {
            revert Forbidden();
        }

        if (eip712Transfers.length != signatures.length) {
            revert LengthMismatch();
        }

        uint256 threshold = (_totalVotingPower * _consensusThreshold) / 100;

        for (uint i = 0; i < eip712Transfers.length; i++) {
            EIP712Transfer memory eip712Transfer = eip712Transfers[i];

            EIP712TransferKey memory transferKey = EIP712TransferKey(
                eip712Transfer.from,
                eip712Transfer.to,
                eip712Transfer.amount,
                eip712Transfer.nftIds,
                eip712Transfer.nonces
            );

            bytes32 eipHash = hash(transferKey);

            if (_firstReported[eipHash] == 0) {
                _firstReported[eipHash] = block.timestamp;
            }

            uint256 expires = _firstReported[eipHash] + _votingTopicExpiration;

            if (block.timestamp > expires) {
                revert TopicExpired(i);
            }

            TransferRequest storage transferData = _transfers[eipHash];

            if (transferData.signers[eip712Transfer.signer]) {
                continue;
            }

            transferData.signers[eip712Transfer.signer] = true;
            Stake memory userStake = _stakes[eip712Transfer.signer];

            if (userStake.amount == 0) {
                revert VotingPowerZero(i);
            }

            if (userStake.unlock <= expires) {
                revert StakeExpiresBeforeVote(i);
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712Transfer, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            transferData.info.amount = eip712Transfer.amount;
            transferData.info.nftIds = eip712Transfer.nftIds;
            transferData.info.from = eip712Transfer.from;
            transferData.info.to = eip712Transfer.to;
            transferData.info.nonces = eip712Transfer.nonces;
            transferData.info.voted += updateGetVotingPower(userStake);

            if (transferData.info.accepted) {
                continue;
            }

            if (transferData.info.voted >= threshold) {
                burnTransferNonces(i, eip712Transfer.to, eip712Transfer.nonces);
                transferData.info.accepted = true;

                bool isTransferFromUnchained = eip712Transfer.from ==
                    address(this);

                _totalVotingPower -= isTransferFromUnchained
                    ? 0
                    : eip712Transfer.amount;

                _stakes[eip712Transfer.from].amount -= isTransferFromUnchained
                    ? 0
                    : eip712Transfer.amount;

                _lockedInUnchained -= isTransferFromUnchained
                    ? eip712Transfer.amount
                    : 0;

                _token.safeTransfer(
                    transferData.info.to,
                    transferData.info.amount
                );

                uint256 nftArrayLength = transferData.info.nftIds.length;

                if (isTransferFromUnchained && nftArrayLength > 0) {
                    revert Forbidden();
                }

                for (uint256 n = 0; n < nftArrayLength; n++) {
                    uint256 nftId = transferData.info.nftIds[n];

                    _nft.safeTransferFrom(
                        address(this),
                        transferData.info.to,
                        nftId,
                        ""
                    );

                    uint256[] storage nftIds = _stakes[eip712Transfer.from]
                        .nftIds;

                    for (uint256 j = 0; j < nftIds.length; j++) {
                        if (nftIds[j] == nftId) {
                            nftIds[j] = nftIds[nftIds.length - 1];
                            nftIds.pop();
                            break;
                        }
                    }
                }

                emit Transfer(
                    transferData.info.from,
                    transferData.info.to,
                    transferData.info.amount,
                    transferData.info.nftIds,
                    transferData.info.nonces
                );
            }
        }
    }

    /**
     * @dev Retrieves the current status of a specific transfer incident
     * identified by a unique EIP712TransferKey. This function computes the hash
     * of the key to look up the transfer incident and returns the TransferInfo
     * struct containing the details of the transfer incident.
     * @param key The EIP712TransferKey struct containing the details needed to
     * identify the transfer incident.
     * @return The TransferInfo struct containing the details of the transfer
     * incident.
     */
    function getTransferData(
        EIP712TransferKey memory key
    ) external view returns (TransferInfo memory) {
        bytes32 eipHash = hash(key);
        TransferRequest storage transferData = _transfers[eipHash];
        return transferData.info;
    }

    /**
     * @dev Retrieves the current status of a specific transfer incident
     * identified by a unique EIP712TransferKey. This function computes the hash
     * of the key to look up the transfer incident and returns a boolean
     * indicating whether the transfer has been signed by a specific address.
     * @param key The EIP712TransferKey struct containing the details needed to
     * identify the transfer incident.
     * @param transferer The address to check for a signature on the transfer
     * incident.
     * @return True if the transfer incident has been signed by the specified
     * address, false otherwise.
     */
    function getRequestedTransfer(
        EIP712TransferKey memory key,
        address transferer
    ) external view returns (bool) {
        bytes32 eipHash = hash(key);
        TransferRequest storage transferData = _transfers[eipHash];
        return transferData.signers[transferer];
    }

    /**
     * @dev Returns the current threshold for transfering to occur. This
     * represents the minimum percentage of total voting power that must agree
     * on a transfer for it to be executed.
     * @return The transfering threshold as a percentage of total voting power.
     */
    function getConsensusThreshold() external view returns (uint256) {
        return _consensusThreshold;
    }

    /**
     * @dev Returns the current voting power for a user.
     * @return The voting power of the user.
     */
    function getVotingPower(bytes20 bls) external view returns (uint256) {
        return getVotingPower(evmAddressOf(bls));
    }

    /**
     * @dev Returns the current voting power for a user.
     * @return The voting power of the user.
     */
    function getVotingPower(address evm) public view returns (uint256) {
        Stake memory userStake = _stakes[evm];
        uint256 votingPower = userStake.amount;

        for (uint256 i = 0; i < userStake.nftIds.length; i++) {
            uint256 nftId = userStake.nftIds[i];
            votingPower += _nftTracker.getPrice(nftId);
        }

        return votingPower;
    }

    /**
     * @dev Returns the current voting power of the user and updates
     * the total voting power of the contract.
     * @return The total voting power of the user.
     */
    function updateGetVotingPower(
        Stake memory userStake
    ) internal returns (uint256) {
        uint256 votingPower = userStake.amount;

        if (address(_nftTracker) == address(0)) {
            votingPower += userStake.nftIds.length;
        } else {
            for (uint256 i = 0; i < userStake.nftIds.length; i++) {
                uint256 nftId = userStake.nftIds[i];
                uint256 cachedPrice = _cachedNftPrices[nftId];
                uint256 livePrice = _nftTracker.getPrice(nftId);

                if (cachedPrice != livePrice) {
                    votingPower += livePrice;
                    _totalVotingPower += livePrice;
                    _totalVotingPower -= _cachedNftPrices[nftId];
                    _cachedNftPrices[nftId] = livePrice;
                } else {
                    votingPower += livePrice;
                }
            }
        }

        return votingPower;
    }

    /**
     * @dev Allows a batch update of contract parameters through a consensus
     * mechanism. This function requires a matching signature for each set of
     * parameters to validate each requester's intent. It enforces a consensus
     * threshold based on the total voting power and prevents execution before a
     * specified block number (_consensusLock) for security.
     * @param eip712SetParams An array of EIP712SetParams structs, each
     * containing a proposed set of parameter updates.
     * @param signatures An array of signatures corresponding to each set of
     * parameters, used to verify the authenticity of the requests.
     * @notice Reverts if called before the consensus lock period ends, if the
     * length of parameters and signatures arrays do not match, if any signature
     * is invalid, or if the voting power threshold for consensus is not met.
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
                eip712SetParam.nftTracker,
                eip712SetParam.threshold,
                eip712SetParam.expiration,
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
                continue;
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712SetParam, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            setParamsData.requesters[eip712SetParam.requester] = true;

            setParamsData.info.voted += updateGetVotingPower(userStake);
            setParamsData.info.token = eip712SetParam.token;
            setParamsData.info.nft = eip712SetParam.nft;
            setParamsData.info.nftTracker = eip712SetParam.nftTracker;
            setParamsData.info.threshold = eip712SetParam.threshold;
            setParamsData.info.expiration = eip712SetParam.expiration;
            setParamsData.info.nonce = eip712SetParam.nonce;

            if (setParamsData.info.accepted) {
                continue;
            }

            if (setParamsData.info.voted >= threshold) {
                setParamsData.info.accepted = true;

                _token = IERC20(setParamsData.info.token);
                _nft = IERC721(setParamsData.info.nft);
                _nftTracker = INFTTracker(setParamsData.info.nftTracker);
                _consensusThreshold = setParamsData.info.threshold;
                _votingTopicExpiration = setParamsData.info.expiration;

                emit ParamsChanged(
                    setParamsData.info.token,
                    setParamsData.info.nft,
                    setParamsData.info.nftTracker,
                    setParamsData.info.threshold,
                    setParamsData.info.expiration,
                    setParamsData.info.voted,
                    setParamsData.info.nonce
                );
            }
        }
    }

    /**
     * @dev Retrieves the detailed information about a set of parameters
     * identified by a hash of the EIP712SetParams struct. This can include the
     * token, NFT addresses, threshold, and the nonce used for the request.
     * @param key The EIP712SetParams struct containing details to identify the
     * parameters.
     * @return ParamsInfo The detailed information of the requested set
     * parameters operation.
     */
    function getSetParamsData(
        EIP712SetParamsKey memory key
    ) external view returns (ParamsInfo memory) {
        bytes32 eipHash = hash(key);
        Params storage setParamsData = _setParams[eipHash];
        return setParamsData.info;
    }

    /**
     * @dev Retrieves the current contract parameters, including the token and
     * NFT addresses, the consensus threshold, and the voting topic expiration.
     * This function returns the current state of the contract's parameters.
     * @return ParamsInfo A struct containing the current contract parameters.
     */
    function getParams() external view returns (ParamsInfo memory) {
        return
            ParamsInfo(
                address(_token),
                address(_nft),
                address(_nftTracker),
                _consensusThreshold,
                _votingTopicExpiration,
                0,
                0,
                true
            );
    }

    /**
     * @dev Checks if a specific address has already requested a set of
     * parameter updates. This is useful for verifying participation in the
     * consensus process for a parameter update.
     * @param key The EIP712SetParams struct containing the details to identify
     * the parameter update request.
     * @param requester The address of the potential requester to check.
     * @return A boolean indicating whether the address has already requested
     * the set of parameters.
     */
    function getRequestedSetParams(
        EIP712SetParamsKey memory key,
        address requester
    ) external view returns (bool) {
        bytes32 eipHash = hash(key);
        Params storage setParamsData = _setParams[eipHash];
        return setParamsData.requesters[requester];
    }

    /**
     * @dev Allows a batch update of NFT prices through a consensus mechanism.
     * This function requires a matching signature for each set of prices to
     * validate each requester's intent. It enforces a consensus threshold based
     * on the total voting power and prevents execution before a specified block
     * number (_consensusLock) for security.
     * @param eip712SetNftPrices An array of EIP712SetNftPrice structs, each
     * containing a proposed set of NFT price updates.
     * @param signatures An array of signatures corresponding to each set of
     * prices, used to verify the authenticity of the requests.
     * @notice Reverts if called before the consensus lock period ends, if the
     * length of prices and signatures arrays do not match, if any signature is
     * invalid, or if the voting power threshold for consensus is not met.
     */
    function setNftPrices(
        EIP712SetNftPrice[] memory eip712SetNftPrices,
        Signature[] memory signatures
    ) external {
        if (block.number <= _consensusLock) {
            revert Forbidden();
        }

        if (eip712SetNftPrices.length != signatures.length) {
            revert LengthMismatch();
        }

        uint256 threshold = (_totalVotingPower * _consensusThreshold) / 100;

        for (uint i = 0; i < eip712SetNftPrices.length; i++) {
            EIP712SetNftPrice memory eip712SetNftPrice = eip712SetNftPrices[i];

            EIP712SetNftPriceKey memory key = EIP712SetNftPriceKey(
                eip712SetNftPrice.nftId,
                eip712SetNftPrice.price,
                eip712SetNftPrice.nonce
            );

            bytes32 eipHash = hash(key);

            if (_firstReported[eipHash] == 0) {
                _firstReported[eipHash] = block.timestamp;
            }

            uint256 expires = _firstReported[eipHash] + _votingTopicExpiration;

            if (block.timestamp > expires) {
                revert TopicExpired(i);
            }

            Stake memory userStake = _stakes[eip712SetNftPrice.requester];

            if (userStake.amount == 0) {
                revert VotingPowerZero(i);
            }

            if (userStake.unlock <= expires) {
                revert StakeExpiresBeforeVote(i);
            }

            NftPrice storage nftPriceData = _setNftPrice[eipHash];

            if (nftPriceData.requesters[eip712SetNftPrice.requester]) {
                continue;
            }

            Signature memory signature = signatures[i];
            bool valid = verify(eip712SetNftPrice, signature);

            if (!valid) {
                revert InvalidSignature(i);
            }

            nftPriceData.requesters[eip712SetNftPrice.requester] = true;

            nftPriceData.info.nftId = eip712SetNftPrice.nftId;
            nftPriceData.info.price = eip712SetNftPrice.price;
            nftPriceData.info.voted += updateGetVotingPower(userStake);

            if (nftPriceData.info.accepted) {
                continue;
            }

            if (nftPriceData.info.voted >= threshold) {
                nftPriceData.info.accepted = true;
                _cachedNftPrices[eip712SetNftPrice.nftId] = eip712SetNftPrice
                    .price;
                _nftTracker.setPrice(
                    eip712SetNftPrice.nftId,
                    eip712SetNftPrice.price
                );
            }
        }
    }

    /**
     * @dev Retrieves the detailed information about a set of NFT prices
     * identified by a hash of the EIP712SetNftPrice struct. This can include
     * the NFT ID and the new price to set.
     * @param key The EIP712SetNftPrice struct containing details to identify
     * the NFT price update.
     * @return NftPriceInfo The detailed information of the requested NFT price
     * update operation.
     */
    function getSetNftPriceData(
        EIP712SetNftPriceKey memory key
    ) external view returns (NftPriceInfo memory) {
        bytes32 eipHash = hash(key);
        NftPrice storage nftPriceData = _setNftPrice[eipHash];
        return nftPriceData.info;
    }

    /**
     * @dev Retrieves the current NFT price for a specific NFT ID. This function
     * returns the current price of the NFT as set by the NFT tracker contract.
     * @param nftId The ID of the NFT to query the price for.
     * @return The current price of the NFT.
     */
    function getNftPrice(uint256 nftId) external view returns (uint256) {
        return _nftTracker.getPrice(nftId);
    }

    /**
     * @dev Checks if a specific address has already requested a set of NFT
     * prices. This is useful for verifying participation in the consensus
     * process for a price update.
     * @param key The EIP712SetNftPrice struct containing the details to
     * identify the NFT price update request.
     * @param requester The address of the potential requester to check.
     * @return A boolean indicating whether the address has already requested
     * the set of NFT prices.
     */
    function getRequestedSetNftPrice(
        EIP712SetNftPriceKey memory key,
        address requester
    ) external view returns (bool) {
        bytes32 eipHash = hash(key);
        NftPrice storage nftPriceData = _setNftPrice[eipHash];
        return nftPriceData.requesters[requester];
    }

    /**
     * @dev Returns the total voting power represented by the sum of all staked
     * tokens. Voting power is used in governance decisions, including the
     * transfering process, where it determines the weight of a participant's
     * vote. This function provides the aggregate voting power at the current
     * state.
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
