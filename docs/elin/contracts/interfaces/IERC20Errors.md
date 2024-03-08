# IERC20Errors







*Standard ERC20 Errors Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.*



## Errors

### ERC20InsufficientAllowance

```solidity
error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)
```



*Indicates a failure with the `spender`’s `allowance`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | Address that may be allowed to operate on tokens without being their owner. |
| allowance | uint256 | Amount of tokens a `spender` is allowed to operate with. |
| needed | uint256 | Minimum amount required to perform a transfer. |

### ERC20InsufficientBalance

```solidity
error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)
```



*Indicates an error related to the current `balance` of a `sender`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | Address whose tokens are being transferred. |
| balance | uint256 | Current balance for the interacting account. |
| needed | uint256 | Minimum amount required to perform a transfer. |

### ERC20InvalidApprover

```solidity
error ERC20InvalidApprover(address approver)
```



*Indicates a failure with the `approver` of a token to be approved. Used in approvals.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| approver | address | Address initiating an approval operation. |

### ERC20InvalidReceiver

```solidity
error ERC20InvalidReceiver(address receiver)
```



*Indicates a failure with the token `receiver`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | Address to which tokens are being transferred. |

### ERC20InvalidSender

```solidity
error ERC20InvalidSender(address sender)
```



*Indicates a failure with the token `sender`. Used in transfers.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | Address whose tokens are being transferred. |

### ERC20InvalidSpender

```solidity
error ERC20InvalidSpender(address spender)
```



*Indicates a failure with the `spender` to be approved. Used in approvals.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | Address that may be allowed to operate on tokens without being their owner. |


