# IERC721Errors







*Standard ERC721 Errors Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.*



## Errors

### ERC721IncorrectOwner

```solidity
error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner)
```



*Indicates an error related to the ownership over a particular token. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | Address whose tokens are being transferred. |
| tokenId | uint256 | Identifier number of a token. |
| owner | address | Address of the current owner of a token. |

### ERC721InsufficientApproval

```solidity
error ERC721InsufficientApproval(address operator, uint256 tokenId)
```



*Indicates a failure with the `operator`’s approval. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | Address that may be allowed to operate on tokens without being their owner. |
| tokenId | uint256 | Identifier number of a token. |

### ERC721InvalidApprover

```solidity
error ERC721InvalidApprover(address approver)
```



*Indicates a failure with the `approver` of a token to be approved. Used in approvals.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| approver | address | Address initiating an approval operation. |

### ERC721InvalidOperator

```solidity
error ERC721InvalidOperator(address operator)
```



*Indicates a failure with the `operator` to be approved. Used in approvals.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | Address that may be allowed to operate on tokens without being their owner. |

### ERC721InvalidOwner

```solidity
error ERC721InvalidOwner(address owner)
```



*Indicates that an address can&#39;t be an owner. For example, `address(0)` is a forbidden owner in EIP-20. Used in balance queries.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | Address of the current owner of a token. |

### ERC721InvalidReceiver

```solidity
error ERC721InvalidReceiver(address receiver)
```



*Indicates a failure with the token `receiver`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | Address to which tokens are being transferred. |

### ERC721InvalidSender

```solidity
error ERC721InvalidSender(address sender)
```



*Indicates a failure with the token `sender`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | Address whose tokens are being transferred. |

### ERC721NonexistentToken

```solidity
error ERC721NonexistentToken(uint256 tokenId)
```



*Indicates a `tokenId` whose `owner` is the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | Identifier number of a token. |


