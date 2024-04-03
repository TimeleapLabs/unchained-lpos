# UnchainedStaking



> Unchained Staking

This contract allows users to stake ERC20 tokens and ERC721 NFTs, offering functionalities to stake, unstake, extend stakes, and manage transfering in case of misbehavior. It implements an EIP-712 domain for secure off-chain signature verifications, enabling decentralized governance actions like voting or transfering without on-chain transactions for each vote. The contract includes a transfering mechanism where staked tokens can be transfered (removed from the stake) if the majority of voting power agrees on a misbehavior.



## Methods

### blsAddressOf

```solidity
function blsAddressOf(address evm) external view returns (bytes20)
```



*Retrieves the BLS address associated with a given EVM address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| evm | address | The EVM address to query the associated BLS address. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes20 | The BLS address associated with the given EVM address. |

### evmAddressOf

```solidity
function evmAddressOf(bytes20 bls) external view returns (address)
```



*Retrieves the EVM address associated with a given BLS address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| bls | bytes20 | The BLS address to query the associated EVM address. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The EVM address associated with the given BLS address. |

### extend

```solidity
function extend(uint256 duration) external nonpayable
```



*Called by a user to extend the duration of their existing stake.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| duration | uint256 | The additional duration to add to the current stake&#39;s unlock time. |

### getChainId

```solidity
function getChainId() external view returns (uint256)
```



*Returns the current chain ID.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The current chain ID. |

### getConsensusThreshold

```solidity
function getConsensusThreshold() external view returns (uint256)
```



*Returns the current threshold for transfering to occur. This represents the minimum percentage of total voting power that must agree on a transfer for it to be executed.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The transfering threshold as a percentage of total voting power. |

### getNftPrice

```solidity
function getNftPrice(uint256 nftId) external view returns (uint256)
```



*Retrieves the current NFT price for a specific NFT ID. This function returns the current price of the NFT as set by the NFT tracker contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftId | uint256 | The ID of the NFT to query the price for. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The current price of the NFT. |

### getParams

```solidity
function getParams() external view returns (struct UnchainedStaking.ParamsInfo)
```



*Retrieves the current contract parameters, including the token and NFT addresses, the consensus threshold, and the voting topic expiration. This function returns the current state of the contract&#39;s parameters.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.ParamsInfo | ParamsInfo A struct containing the current contract parameters. |

### getRequestedSetNftPrice

```solidity
function getRequestedSetNftPrice(UnchainedStaking.EIP712SetNftPriceKey key, address requester) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712SetNftPriceKey | undefined |
| requester | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getRequestedSetParams

```solidity
function getRequestedSetParams(UnchainedStaking.EIP712SetParamsKey key, address requester) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712SetParamsKey | undefined |
| requester | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getRequestedTransferOut

```solidity
function getRequestedTransferOut(UnchainedStaking.EIP712TransferKey key, address transferer) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712TransferKey | undefined |
| transferer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getSetNftPriceData

```solidity
function getSetNftPriceData(UnchainedStaking.EIP712SetNftPriceKey key) external view returns (struct UnchainedStaking.NftPriceInfo)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712SetNftPriceKey | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.NftPriceInfo | undefined |

### getSetParamsData

```solidity
function getSetParamsData(UnchainedStaking.EIP712SetParamsKey key) external view returns (struct UnchainedStaking.ParamsInfo)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712SetParamsKey | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.ParamsInfo | undefined |

### getStake

```solidity
function getStake(address evm) external view returns (struct UnchainedStaking.Stake)
```



*Retrieves the stake information associated with a given EVM address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| evm | address | The EVM address to query the stake information. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.Stake | The stake information associated with the given EVM address. |

### getStake

```solidity
function getStake(bytes20 bls) external view returns (struct UnchainedStaking.Stake)
```



*Retrieves the stake information associated with a given BLS address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| bls | bytes20 | The BLS address to query the stake information. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.Stake | The stake information associated with the given BLS address. |

### getTotalVotingPower

```solidity
function getTotalVotingPower() external view returns (uint256)
```



*Returns the total voting power represented by the sum of all staked tokens. Voting power is used in governance decisions, including the transfering process, where it determines the weight of a participant&#39;s vote. This function provides the aggregate voting power at the current state.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The total voting power from all staked tokens. |

### getTransferOutData

```solidity
function getTransferOutData(UnchainedStaking.EIP712TransferKey key) external view returns (struct UnchainedStaking.TransferInfo)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| key | UnchainedStaking.EIP712TransferKey | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.TransferInfo | undefined |

### getVotingPower

```solidity
function getVotingPower(bytes20 bls) external view returns (uint256)
```



*Returns the current voting power for a user.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| bls | bytes20 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The voting power of the user. |

### getVotingPower

```solidity
function getVotingPower(address evm) external view returns (uint256)
```



*Returns the current voting power for a user.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| evm | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The voting power of the user. |

### increaseStake

```solidity
function increaseStake(uint256 amount, uint256[] nftIds) external nonpayable
```



*Called by a user to increase their stake amount and optionally add more NFTs to the stake.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The additional amount of tokens to add to the existing stake. |
| nftIds | uint256[] | An array of additional NFT IDs to add to the stake. |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external view returns (bytes4)
```



*Ensures that this contract can receive NFTs safely. Reverts if the NFT is not the expected one.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | The selector to confirm the contract implements the ERC721Received interface. |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### recoverERC20

```solidity
function recoverERC20(address token, address recipient, uint256 amount) external nonpayable
```



*Sends `amount` of ERC20 `token` from contract address to `recipient` Useful if someone sent ERC20 tokens to the contract address by mistake.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | The address of the ERC20 token contract. |
| recipient | address | The address to which the tokens should be transferred. |
| amount | uint256 | The amount of tokens to transfer. |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### setBlsAddress

```solidity
function setBlsAddress(bytes20 blsAddress) external nonpayable
```



*Allows a user to set or update their BLS (Boneh-Lynn-Shacham) address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| blsAddress | bytes20 | The new BLS address to be set for the user. |

### setNftPrices

```solidity
function setNftPrices(UnchainedStaking.EIP712SetNftPrice[] eip712SetNftPrices, UnchainedStaking.Signature[] signatures) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712SetNftPrices | UnchainedStaking.EIP712SetNftPrice[] | undefined |
| signatures | UnchainedStaking.Signature[] | undefined |

### setParams

```solidity
function setParams(UnchainedStaking.EIP712SetParams[] eip712SetParams, UnchainedStaking.Signature[] signatures) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712SetParams | UnchainedStaking.EIP712SetParams[] | undefined |
| signatures | UnchainedStaking.Signature[] | undefined |

### setSigner

```solidity
function setSigner(UnchainedStaking.EIP712SetSigner eip712SetSigner, UnchainedStaking.Signature stakerSignature, UnchainedStaking.Signature signerSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712SetSigner | UnchainedStaking.EIP712SetSigner | undefined |
| stakerSignature | UnchainedStaking.Signature | undefined |
| signerSignature | UnchainedStaking.Signature | undefined |

### signerToStaker

```solidity
function signerToStaker(address signer) external view returns (address)
```



*Returns the staker address associated with a given signer address. This can be used to look up the controlling staker of a signer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The address of the signer. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the staker who set the signer. |

### stake

```solidity
function stake(uint256 duration, uint256 amount, uint256[] nftIds) external nonpayable
```



*Called by a user to stake their tokens along with NFTs if desired.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| duration | uint256 | The duration for which the tokens and NFTs are staked. |
| amount | uint256 | The amount of tokens to stake. |
| nftIds | uint256[] | An array of NFT IDs to stake along with the tokens. |

### stakerToSigner

```solidity
function stakerToSigner(address staker) external view returns (address)
```



*Returns the signer address associated with a given staker address. This function allows querying who has been designated as the signer for a staker.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | The address of the staker. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the signer set by the staker. |

### transferIn

```solidity
function transferIn(uint256 amount) external nonpayable
```

Allows transfering tokens to the Unchained Network.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of tokens to transfer to the Unchained Network. |

### transferOut

```solidity
function transferOut(UnchainedStaking.EIP712Transfer[] eip712Transferes, UnchainedStaking.Signature[] signatures) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712Transferes | UnchainedStaking.EIP712Transfer[] | undefined |
| signatures | UnchainedStaking.Signature[] | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### unstake

```solidity
function unstake() external nonpayable
```



*Called by a user to unstake their tokens and NFTs once the stake duration has ended.*


### verify

```solidity
function verify(UnchainedStaking.EIP712Transfer eip712Transfer, UnchainedStaking.Signature signature) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712Transfer | UnchainedStaking.EIP712Transfer | undefined |
| signature | UnchainedStaking.Signature | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### verify

```solidity
function verify(UnchainedStaking.EIP712SetSigner eip712SetSigner, UnchainedStaking.Signature stakerSignature, UnchainedStaking.Signature signerSignature) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712SetSigner | UnchainedStaking.EIP712SetSigner | undefined |
| stakerSignature | UnchainedStaking.Signature | undefined |
| signerSignature | UnchainedStaking.Signature | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### Accused

```solidity
event Accused(address accused, address accuser, uint256 amount, uint256 voted, bytes32 incident)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| accused  | address | undefined |
| accuser  | address | undefined |
| amount  | uint256 | undefined |
| voted  | uint256 | undefined |
| incident  | bytes32 | undefined |

### BlsAddressChanged

```solidity
event BlsAddressChanged(address user, bytes32 from, bytes32 to)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| from  | bytes32 | undefined |
| to  | bytes32 | undefined |

### Extended

```solidity
event Extended(address user, uint256 unlock)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| unlock  | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### ParamsChanged

```solidity
event ParamsChanged(address token, address nft, address nftTracker, uint256 threshold, uint256 expiration, uint256 voted, uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token  | address | undefined |
| nft  | address | undefined |
| nftTracker  | address | undefined |
| threshold  | uint256 | undefined |
| expiration  | uint256 | undefined |
| voted  | uint256 | undefined |
| nonce  | uint256 | undefined |

### SignerChanged

```solidity
event SignerChanged(address staker, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker  | address | undefined |
| signer  | address | undefined |

### StakeIncreased

```solidity
event StakeIncreased(address user, uint256 amount, uint256[] nftIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| amount  | uint256 | undefined |
| nftIds  | uint256[] | undefined |

### Staked

```solidity
event Staked(address user, uint256 unlock, uint256 amount, uint256[] nftIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| unlock  | uint256 | undefined |
| amount  | uint256 | undefined |
| nftIds  | uint256[] | undefined |

### TransferIn

```solidity
event TransferIn(address from, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from  | address | undefined |
| amount  | uint256 | undefined |

### TransferOut

```solidity
event TransferOut(address to, uint256 amount, uint256[] nftIds, uint256[] nonces)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to  | address | undefined |
| amount  | uint256 | undefined |
| nftIds  | uint256[] | undefined |
| nonces  | uint256[] | undefined |

### UnStaked

```solidity
event UnStaked(address user, uint256 amount, uint256[] nftIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| amount  | uint256 | undefined |
| nftIds  | uint256[] | undefined |

### VotedForParams

```solidity
event VotedForParams(address user, uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| nonce  | uint256 | undefined |



## Errors

### AddressEmptyCode

```solidity
error AddressEmptyCode(address target)
```



*There&#39;s no code at `target` (it is not a contract).*

#### Parameters

| Name | Type | Description |
|---|---|---|
| target | address | undefined |

### AddressInUse

```solidity
error AddressInUse()
```






### AddressInsufficientBalance

```solidity
error AddressInsufficientBalance(address account)
```



*The ETH balance of the account is not enough to perform the operation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### AddressZero

```solidity
error AddressZero()
```






### AlreadyAccused

```solidity
error AlreadyAccused(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### AlreadyStaked

```solidity
error AlreadyStaked()
```






### AlreadyVoted

```solidity
error AlreadyVoted(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### AmountZero

```solidity
error AmountZero()
```






### BlsNotSet

```solidity
error BlsNotSet()
```






### DurationZero

```solidity
error DurationZero()
```






### ECDSAInvalidSignature

```solidity
error ECDSAInvalidSignature()
```



*The signature derives the `address(0)`.*


### ECDSAInvalidSignatureLength

```solidity
error ECDSAInvalidSignatureLength(uint256 length)
```



*The signature has an invalid length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| length | uint256 | undefined |

### ECDSAInvalidSignatureS

```solidity
error ECDSAInvalidSignatureS(bytes32 s)
```



*The signature has an S value that is in the upper half order.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| s | bytes32 | undefined |

### FailedInnerCall

```solidity
error FailedInnerCall()
```



*A call to an address target failed. The target may have reverted.*


### Forbidden

```solidity
error Forbidden()
```






### InvalidSignature

```solidity
error InvalidSignature(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### LengthMismatch

```solidity
error LengthMismatch()
```






### NonceUsed

```solidity
error NonceUsed(uint256 index, uint256 nonce)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |
| nonce | uint256 | undefined |

### NotConsumer

```solidity
error NotConsumer(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### NotUnlocked

```solidity
error NotUnlocked()
```






### OwnableInvalidOwner

```solidity
error OwnableInvalidOwner(address owner)
```



*The owner is not a valid owner account. (eg. `address(0)`)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

### OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount(address account)
```



*The caller account is not authorized to perform an operation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### ReentrancyGuardReentrantCall

```solidity
error ReentrancyGuardReentrantCall()
```



*Unauthorized reentrant call.*


### SafeERC20FailedOperation

```solidity
error SafeERC20FailedOperation(address token)
```



*An operation with an ERC20 token failed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |

### StakeExpiresBeforeVote

```solidity
error StakeExpiresBeforeVote(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### StakeZero

```solidity
error StakeZero()
```






### TopicExpired

```solidity
error TopicExpired(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### VotingPowerZero

```solidity
error VotingPowerZero(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### WrongEIP712Signature

```solidity
error WrongEIP712Signature()
```






### WrongNFT

```solidity
error WrongNFT()
```







