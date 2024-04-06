# NFTTracker



> NFTTracker



*Contract to track the prices of NFTs*

## Methods

### getPrice

```solidity
function getPrice(uint256 nftId) external view returns (uint256)
```



*Get the price of an NFT*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftId | uint256 | The id of the NFT |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The price of the NFT |

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


### setPrice

```solidity
function setPrice(uint256 nftId, uint256 price) external nonpayable
```



*Set the price of an NFT*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftId | uint256 | The id of the NFT |
| price | uint256 | The price of the NFT |

### setPrices

```solidity
function setPrices(uint256[] nftIds, uint256[] prices) external nonpayable
```



*Set the prices of multiple NFTs*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftIds | uint256[] | The ids of the NFTs |
| prices | uint256[] | The prices of the NFTs |

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

### LengthMismatch

```solidity
error LengthMismatch()
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


