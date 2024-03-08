# SafeERC20



> SafeERC20



*Wrappers around ERC20 operations that throw on failure (when the token contract returns false). Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful. To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract, which allows you to call the safe operations as `token.safeTransfer(...)`, etc.*



## Errors

### SafeERC20FailedDecreaseAllowance

```solidity
error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease)
```



*Indicates a failed `decreaseAllowance` request.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| currentAllowance | uint256 | undefined |
| requestedDecrease | uint256 | undefined |

### SafeERC20FailedOperation

```solidity
error SafeERC20FailedOperation(address token)
```



*An operation with an ERC20 token failed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | undefined |


