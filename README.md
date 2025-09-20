# Proof of Audit on Stacks

This project provides a simple Clarity smart contract to create an immutable,
timestamped proof of an audit report's existence (or any other document) on the
Stacks blockchain.

By storing a SHA256 hash of a document on-chain, you can cryptographically prove
that the document existed at a specific point in time, corresponding to the
block height at which the hash was anchored.

## How It Works

1. Off-chain, create a SHA256 hash of the report, document, or data you want to
   notarize.

2. The contract deployer calls the anchor-hash function with this hash. The
   contract stores the hash and the current block height in a map.

3. At any time, anyone can call the read-only get-audit-info function with a
   hash to retrieve the block height at which it was recorded. This serves as an
   irrefutable, timestamped proof of existence.

## Contract Functions

### anchor-hash

- (public function)

- Parameter: hash (buff 32) - The SHA256 hash of the data.

- Description: Stores the hash and the current block-height on-chain.

- Access: Can only be called by the contract deployer. The transaction will fail
  if called by any other principal or if the hash has already been anchored.

### get-audit-info

- (read-only function)

- Parameter: hash (buff 32) - The hash to verify.

- Description: Returns an optional tuple containing the block-height if the hash
  has been previously anchored. If the hash is not found, it returns none.
