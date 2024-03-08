# FixedStaking



> FixedStaking

This contract develops rolling, fixed rate staking programs for a specific token, allowing users to stake an NFT from a specific collection to earn 2x rewards.



## Methods

### addRewards

```solidity
function addRewards(uint256 amount) external nonpayable
```



*Adds rewards from the pool.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of rewards to add. |

### addStakeProgram

```solidity
function addStakeProgram(Storage.StakeProgram value) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value | Storage.StakeProgram | undefined |

### deleteStakeProgram

```solidity
function deleteStakeProgram(uint256 id) external nonpayable
```

Emits a StakeProgramDeleted event on success.

*Deletes a StakeProgram record by its ID and updates relevant indexes.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | The ID of the record to delete. |

### getDatabase

```solidity
function getDatabase() external view returns (address)
```



*Returns the on-chain SolidQuery database address.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

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
| _0 | bytes4 | undefined |

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

### removeRewards

```solidity
function removeRewards(uint256 amount) external nonpayable
```



*Removes rewards from the pool if there are any remaining.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of rewards to remove. |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### setEarlyUnlock

```solidity
function setEarlyUnlock(bool status) external nonpayable
```



*Panic mode: let everyone unstake NOW.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| status | bool | Set early unlock on or off. |

### stakeTokens

```solidity
function stakeTokens(uint256 programId, uint256 amount) external nonpayable
```



*Called by a user to stake their tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| programId | uint256 | The id of the staking program for this stake. |
| amount | uint256 | The amount of tokens to stake. |

### stakeTokensWithNft

```solidity
function stakeTokensWithNft(uint256 programId, uint256 amount, uint256 nftId) external nonpayable
```



*Called by a user to stake their tokens with an NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| programId | uint256 | The id of the staking program for this stake. |
| amount | uint256 | The amount of tokens to stake. |
| nftId | uint256 | The NFT ID to use for bonus rewards. |

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
function unstake(uint256 stakeId) external nonpayable
```



*Called by a user to unstake an unlocked stake.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| stakeId | uint256 | The id of the stake record to unstake. |

### updateStakeProgram

```solidity
function updateStakeProgram(uint256 id, Storage.StakeProgram value) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| value | Storage.StakeProgram | undefined |



## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### RewardsAdded

```solidity
event RewardsAdded(uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount  | uint256 | undefined |

### RewardsRemoved

```solidity
event RewardsRemoved(uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount  | uint256 | undefined |



