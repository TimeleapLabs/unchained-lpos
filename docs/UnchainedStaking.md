# UnchainedStaking



> UnchainedStaking

This contract allows users to stake ERC20 tokens and ERC721 NFTs, offering functionalities to stake, unstake, extend stakes, and manage slashing in case of misbehavior. It implements an EIP-712 domain for secure off-chain signature verifications, enabling decentralized governance actions like voting or slashing without on-chain transactions for each vote. The contract includes a slashing mechanism where staked tokens can be slashed (removed from the stake) if the majority of voting power agrees on a misbehavior. Users can stake tokens and NFTs either as consumers or not, affecting their roles within the ecosystem, particularly in governance or voting processes.



## Methods

### blsAddressOf

```solidity
function blsAddressOf(address evm) external view returns (bytes32)
```



*Retrieves the BLS address associated with a given EVM address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| evm | address | The EVM address to query the associated BLS address. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | The BLS address associated with the given EVM address. |

### evmAddressOf

```solidity
function evmAddressOf(bytes32 bls) external view returns (address)
```



*Retrieves the EVM address associated with a given BLS address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| bls | bytes32 | The BLS address to query the associated EVM address. |

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

### getSlashThreshold

```solidity
function getSlashThreshold() external view returns (uint256)
```



*Returns the current threshold for slashing to occur. This represents the minimum percentage of total voting power that must agree on a slash for it to be executed.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The slashing threshold as a percentage of total voting power. |

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

### isConsumer

```solidity
function isConsumer(address addr) external view returns (bool)
```



*Checks if the stake associated with a given address is marked as consumer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | The address to check the consumer flag for. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | True if the stake is marked as consumer, false otherwise. |

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
function setBlsAddress(bytes32 blsAddress) external nonpayable
```



*Allows a user to set or update their BLS (Boneh-Lynn-Shacham) address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| blsAddress | bytes32 | The new BLS address to be set for the user. |

### setSlashThreshold

```solidity
function setSlashThreshold(uint256 threshold) external nonpayable
```



*Sets the minimum percentage of total voting power required to successfully execute a slash. Only callable by the contract owner. The threshold must be at least 51% to ensure a majority vote.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| threshold | uint256 | The new slashing threshold as a percentage. |

### slash

```solidity
function slash(UnchainedStaking.EIP712Slash[] eip712Slashes, UnchainedStaking.Signature[] signatures) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712Slashes | UnchainedStaking.EIP712Slash[] | undefined |
| signatures | UnchainedStaking.Signature[] | undefined |

### stake

```solidity
function stake(uint256 duration, uint256 amount, uint256[] nftIds, bool consumer) external nonpayable
```



*Called by a user to stake their tokens along with NFTs if desired, specifying whether the stake is for a consumer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| duration | uint256 | The duration for which the tokens and NFTs are staked. |
| amount | uint256 | The amount of tokens to stake. |
| nftIds | uint256[] | An array of NFT IDs to stake along with the tokens. |
| consumer | bool | A boolean indicating whether the stake is for a consumer or not. |

### stakeOf

```solidity
function stakeOf(bytes32 bls) external view returns (struct UnchainedStaking.Stake)
```



*Retrieves the stake information associated with a given BLS address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| bls | bytes32 | The BLS address to query the stake information. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | UnchainedStaking.Stake | The stake information associated with the given BLS address. |

### stakeOf

```solidity
function stakeOf(address evm) external view returns (struct UnchainedStaking.Stake)
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

### transfer

```solidity
function transfer(UnchainedStaking.EIP712Transfer[] eip712Transfers, UnchainedStaking.Signature[] signatures) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712Transfers | UnchainedStaking.EIP712Transfer[] | undefined |
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



## Events

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

### SlashThresholdChanged

```solidity
event SlashThresholdChanged(uint256 from, uint256 to)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from  | uint256 | undefined |
| to  | uint256 | undefined |

### Slashed

```solidity
event Slashed(address consumer, address accuser, uint256 amount, uint256 voted, bytes32 incident)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| consumer  | address | undefined |
| accuser  | address | undefined |
| amount  | uint256 | undefined |
| voted  | uint256 | undefined |
| incident  | bytes32 | undefined |

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
event Staked(address user, uint256 unlock, uint256 amount, uint256[] nftIds, bool consumer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user  | address | undefined |
| unlock  | uint256 | undefined |
| amount  | uint256 | undefined |
| nftIds  | uint256[] | undefined |
| consumer  | bool | undefined |

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

### AddressInsufficientBalance

```solidity
error AddressInsufficientBalance(address account)
```



*The ETH balance of the account is not enough to perform the operation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### AlreadyAccused

```solidity
error AlreadyAccused(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### AlreadySlashed

```solidity
error AlreadySlashed(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### AlreadyStaked

```solidity
error AlreadyStaked()
```






### AmountZero

```solidity
error AmountZero()
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

### StakeZero

```solidity
error StakeZero()
```






### VotingPowerZero

```solidity
error VotingPowerZero(uint256 index)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### WrongAccused

```solidity
error WrongAccused(uint256 index)
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







