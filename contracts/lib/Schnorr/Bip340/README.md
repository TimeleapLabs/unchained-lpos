# Schnorr Library

Solidity implementation of BIP340 Schnorr signatures, to be able to verify
Taproot-compliant signatures on Ethereum. This library includes files copied
from [zeroDAO](https://github.com/zerodao-finance/bip340-solidity), which is
licensed under the MIT License.

## Usage

At a high level, we need to pass 3 things to verify a BIP340 signature are
structured as follows:

- public key, as 32 byte X coordinate ("xonly" pubkey)
- signature, 64 bytes
  - `r` commitment, 32 bytes
  - `s` proof, 32 bytes
- message hash, arbitrary 32 bytes

We typically refer to these in code as `px`, `rx`, `s`, and `m`. If there's a
list of them, we add a `v` suffix for "vector". These must values must be
taken apart from the byte representations before being passed to the verifier
code.

All of these values being 32 bytes is convenient on the EVM, as they exactly
occupy a stack element or storage slot. This is all encapsulated by the
`Bip340Verifier` interface. It's presumed that either of the contracts would be
deployed as libraries, accessed with a common interface (see below).

The main functions of interest are:

- `Bip340` in general (`Naive` and `Ecrec` variants, behind `Bip340Verifier`)
  - `verify(uint256 px, uint256 rx, uint256 s, bytes32 m)`
- `Bip340Naive`
  - `verifyFull(uint256 px, uint256 py, uint256 rx, uint256 s, bytes32 m)` (may save some gas compared to naive end-to-end verify, using precomputed y coord)
- `Bip340Batch`
  - `verifyBatch(uint256 px, uint256[] rxv, uint256[] sv, bytes32[] mv, uint256[] av)`
  - `verifyBatchFull(uint256 px, uint256 py, uint256[] rxv, uint256[] sv, bytes32[] mv, uint256[] av)`
- `Bip340Util`
  - `liftX(uint256 px)` returning Y coordinate and success

### Spec-mirroring "naive" impl

The naive impl implements a verifier according to the spec as well as it can.
This is in the `Bip340Naive.sol` and the `Bip340Batch.sol` contracts.

The `Full` variants of the functions vary from the non-`Full` ones in that they
require the y coordinate of the public key to be provided precomputed. This
can be done safely by using the `liftX` function from the `Bip340Util` library.

The `a` values provided in the batch functions are a set of blinding values to
prevent a cancellation attack. These have a [standard process](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki#batch-verification)
for generating them deterministically, but any value in the range of `1..n-1`
(where n is the curve order) can be used. A lazy way to do this is by taking
some randomness from after the signatures were generated (`prevrandao` is
fine), and repeatedly hashing it with a counter. The length of this vector
must be 1 less than the number of signatures being verified, so verifying a
single signature with the batch verifier would not provide any `a` values.

### Optimized impl

The `EcrecHack` variant uses a hack with the `ecrecover` precompile to verify
the signature much more efficiently. It doesn't implement the verification
algorithm described in the spec, but it is equally correct, and since it uses
the precompile, a tremendous amount is saved on gas and on-chain bytecode space.

You probably want to use this one.
