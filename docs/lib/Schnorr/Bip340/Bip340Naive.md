# Bip340Naive









## Methods

### verify

```solidity
function verify(uint256 px, uint256 rx, uint256 s, bytes32 m) external pure returns (bool)
```

Verifies a BIP340 signature parsed as `(rx, s)` form against a message `m` and a pubkey&#39;s x coord `px`. px - public key x coordinate rx - signature r commitment s - signature s proof m - message hash



#### Parameters

| Name | Type | Description |
|---|---|---|
| px | uint256 | undefined |
| rx | uint256 | undefined |
| s | uint256 | undefined |
| m | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### verifyFull

```solidity
function verifyFull(uint256 _px, uint256 _py, uint256 rx, uint256 s, bytes32 m) external pure returns (bool)
```

Verifies a BIP340 signature parsed as `(rx, s)` form against a message `m` and pubkey coords `px` and `py`.  The pubkey must already be on the curve because we skip some checks with it. px, py - public key coordinates rx - signature r commitment s - signature s proof m - message hash



#### Parameters

| Name | Type | Description |
|---|---|---|
| _px | uint256 | undefined |
| _py | uint256 | undefined |
| rx | uint256 | undefined |
| s | uint256 | undefined |
| m | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




