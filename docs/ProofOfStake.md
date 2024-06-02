# ProofOfStake









## Methods

### eip712DomainHash

```solidity
function eip712DomainHash() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### extendStake

```solidity
function extendStake(uint256 duration) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| duration | uint256 | undefined |

### getStake

```solidity
function getStake(address user) external view returns (struct ProofOfStake.Stake)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ProofOfStake.Stake | undefined |

### getValidators

```solidity
function getValidators() external view returns (address[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### getValidators

```solidity
function getValidators(uint256 start, uint256 end) external view returns (address[])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| start | uint256 | undefined |
| end | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### increaseStake

```solidity
function increaseStake(uint256 amount, uint256[] nfts) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| nfts | uint256[] | undefined |

### nftPrices

```solidity
function nftPrices(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### nftToken

```solidity
function nftToken() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### owner

```solidity
function owner() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### processed

```solidity
function processed(bytes32) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### safeVerify

```solidity
function safeVerify(bytes32 eip712Hash, SchnorrSignature.Signature schnorrSignature) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| eip712Hash | bytes32 | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### schnorrParticipationThreshold

```solidity
function schnorrParticipationThreshold() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setNftPrices

```solidity
function setNftPrices(SetNftPrices.NftPrices prices, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prices | SetNftPrices.NftPrices | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### setSchNorrParticipationThreshold

```solidity
function setSchNorrParticipationThreshold(SetSchnorrThreshold.SchnorrThreshold threshold, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| threshold | SetSchnorrThreshold.SchnorrThreshold | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### stake

```solidity
function stake(uint256 amount, uint256 duration, uint256[] nfts) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| duration | uint256 | undefined |
| nfts | uint256[] | undefined |

### stakes

```solidity
function stakes(address) external view returns (uint256 amount, uint256 end, uint256 nftSum)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |
| end | uint256 | undefined |
| nftSum | uint256 | undefined |

### stakingToken

```solidity
function stakingToken() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### transfer

```solidity
function transfer(SchnorrTransfer.Transfer txn, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| txn | SchnorrTransfer.Transfer | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### transferNft

```solidity
function transferNft(SchnorrNftTransfer.Transfer txn, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| txn | SchnorrNftTransfer.Transfer | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### transferOwnership

```solidity
function transferOwnership(SchnorrTransferOwnership.TransferOwnership txn, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| txn | SchnorrTransferOwnership.TransferOwnership | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### verifySetNftPrice

```solidity
function verifySetNftPrice(SetNftPrices.NftPrices prices, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prices | SetNftPrices.NftPrices | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### verifySetSchnorrThreshold

```solidity
function verifySetSchnorrThreshold(SetSchnorrThreshold.SchnorrThreshold threshold, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| threshold | SetSchnorrThreshold.SchnorrThreshold | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### verifyTransfer

```solidity
function verifyTransfer(SchnorrTransfer.Transfer txn, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| txn | SchnorrTransfer.Transfer | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### verifyTransferNft

```solidity
function verifyTransferNft(SchnorrNftTransfer.Transfer txn, SchnorrSignature.Signature schnorrSignature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| txn | SchnorrNftTransfer.Transfer | undefined |
| schnorrSignature | SchnorrSignature.Signature | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```








## Events

### Extended

```solidity
event Extended(address indexed user, uint256 end)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| end  | uint256 | undefined |

### Increased

```solidity
event Increased(address indexed user, uint256 amount, uint256[] nfts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| amount  | uint256 | undefined |
| nfts  | uint256[] | undefined |

### Staked

```solidity
event Staked(address indexed user, uint256 amount, uint256 end, uint256[] nfts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| amount  | uint256 | undefined |
| end  | uint256 | undefined |
| nfts  | uint256[] | undefined |

### Withdrawn

```solidity
event Withdrawn(address indexed user, uint256 amount, uint256[] nfts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| amount  | uint256 | undefined |
| nfts  | uint256[] | undefined |



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

### AlreadyProcessed

```solidity
error AlreadyProcessed()
```






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






### ElementAlreadyExists

```solidity
error ElementAlreadyExists()
```






### ElementDoesNotExist

```solidity
error ElementDoesNotExist()
```






### FailedInnerCall

```solidity
error FailedInnerCall()
```



*A call to an address target failed. The target may have reverted.*


### IndexOutOfBounds

```solidity
error IndexOutOfBounds(uint256 index, uint256 length)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |
| length | uint256 | undefined |

### InvalidSchorrSignature

```solidity
error InvalidSchorrSignature()
```






### InvalidSlice

```solidity
error InvalidSlice(uint256 start, uint256 end)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| start | uint256 | undefined |
| end | uint256 | undefined |

### NftNotInStake

```solidity
error NftNotInStake()
```






### NoStakeToExtend

```solidity
error NoStakeToExtend()
```






### SafeERC20FailedOperation

```solidity
error SafeERC20FailedOperation(address token)
```



*An operation with an ERC20 token failed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |


