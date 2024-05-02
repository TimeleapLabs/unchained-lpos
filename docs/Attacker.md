# Attacker









## Methods

### approve

```solidity
function approve(address addr, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |
| amount | uint256 | undefined |

### attack

```solidity
function attack() external nonpayable
```






### contractOwner

```solidity
function contractOwner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### setBls

```solidity
function setBls(bytes20 blsAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| blsAddress | bytes20 | undefined |

### stakeToStakingContract

```solidity
function stakeToStakingContract(uint256 duration, uint256 amount, uint256[] nftIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| duration | uint256 | undefined |
| amount | uint256 | undefined |
| nftIds | uint256[] | undefined |

### target

```solidity
function target() external view returns (contract UnchainedStaking)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract UnchainedStaking | undefined |

### token

```solidity
function token() external view returns (contract IERC20)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IERC20 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### AttackFailed

```solidity
event AttackFailed(string error)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| error  | string | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



## Errors

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



