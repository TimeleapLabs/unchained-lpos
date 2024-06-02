# SchnorrUser









## Methods

### eip712DomainHash

```solidity
function eip712DomainHash() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

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




## Errors

### AlreadyProcessed

```solidity
error AlreadyProcessed()
```






### InvalidSchorrSignature

```solidity
error InvalidSchorrSignature()
```







