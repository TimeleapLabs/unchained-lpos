# Bip340Batch









## Methods

### verifyBatch

```solidity
function verifyBatch(uint256 px, uint256[] rxv, uint256[] sv, bytes32[] mv, uint256[] av) external pure returns (bool)
```

Same as `verifyBatch`, but derives the Y coordinate on the fly.  You probably don&#39;t want to use this and should just precompute the y coordinate on-chain.



#### Parameters

| Name | Type | Description |
|---|---|---|
| px | uint256 | undefined |
| rxv | uint256[] | undefined |
| sv | uint256[] | undefined |
| mv | bytes32[] | undefined |
| av | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### verifyBatchFull

```solidity
function verifyBatchFull(uint256 px, uint256 py, uint256[] rxv, uint256[] sv, bytes32[] mv, uint256[] av) external pure returns (bool)
```

Batch verification.  Just like the above.  Pass everything as lists of all the same length. The av vector should be independently randomly sampled variables, with length 1 less than the other vectors.  These should be sampled *after* the signature verification to be safe, otherwise there&#39;s tricks a malicious signer could screw things up.  This can be done by hashing pubkeys and messages and sigs, perhaps with some other randomness. In a few places, we use functions returning (-1, 0) to signal a check failed and the full signature verification is wrong, but we don&#39;t propagate up where.  Although checking with a typical verifier should be able to infer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| px | uint256 | undefined |
| py | uint256 | undefined |
| rxv | uint256[] | undefined |
| sv | uint256[] | undefined |
| mv | bytes32[] | undefined |
| av | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




