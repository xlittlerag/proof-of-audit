import { Cl, cvToValue } from "@stacks/transactions";
import { describe, it, expect } from "vitest";
import { sha256 } from "@noble/hashes/sha256";

// --- Test Suite: proof-of-audit ---
describe("proof-of-audit contract tests", () => {
  // Helper function to create a SHA256 hash buffer from a string,
  // which is how the contract expects to receive the hash.
  const createHash = (data: string) => sha256(data);

  // Gets the deployer and other wallets from the Clarinet configuration.
  const accounts = simnet.getAccounts();
  const deployer = accounts.get("deployer")!;
  const nonDeployer = accounts.get("wallet_1")!;

  // Test Case 1: Successful Hash Anchoring by Deployer
  it("should allow the deployer to anchor a new hash", () => {
    const hash = createHash("my-first-audit-report.pdf");

    // Act: Call the anchor-hash function from the deployer's account.
    const result = simnet.callPublicFn(
      "proof-of-audit",
      "anchor-hash",
      [Cl.buffer(hash)],
      deployer,
    );

    // Assert: The transaction should be successful and return (ok true).
    expect(result.result).toBeOk(Cl.bool(true));
  });

  // Test Case 2: Unauthorized Anchor Attempt
  it("should not allow a non-deployer to anchor a hash", () => {
    const hash = createHash("unauthorized-report.docx");

    // Act: Call the anchor-hash function from a different account.
    const result = simnet.callPublicFn(
      "proof-of-audit",
      "anchor-hash",
      [Cl.buffer(hash)],
      nonDeployer,
    );

    // Assert: The transaction should fail with err u100 (ERR-HASH-ALREADY-EXISTS).
    // Note: The contract uses the same error code for unauthorized and duplicate hashes.
    expect(result.result).toBeErr(Cl.uint(100));
  });

  // Test Case 3: Duplicate Hash Rejection
  it("should not allow the same hash to be anchored twice", () => {
    const hash = createHash("a-report-to-duplicate.txt");

    // Act (First Call): Anchor the hash successfully.
    simnet.callPublicFn(
      "proof-of-audit",
      "anchor-hash",
      [Cl.buffer(hash)],
      deployer,
    );

    // Mine a block to confirm the first transaction.
    simnet.mineEmptyBlock();

    // Act (Second Call): Attempt to anchor the same hash again.
    const result = simnet.callPublicFn(
      "proof-of-audit",
      "anchor-hash",
      [Cl.buffer(hash)],
      deployer,
    );

    // Assert: The second transaction should fail with err u100.
    expect(result.result).toBeErr(Cl.uint(100));
  });

  // Test Case 4: Data Retrieval and Verification
  it("should return audit info for an existing hash and none for a non-existing hash", () => {
    const existingHash = createHash("a-report-that-exists.json");
    const nonExistingHash = createHash("this-report-does-not-exist.zip");

    // Arrange: Anchor the existing hash. This happens at block 2.
    simnet.callPublicFn(
      "proof-of-audit",
      "anchor-hash",
      [Cl.buffer(existingHash)],
      deployer,
    );

    // Act & Assert (Existing Hash):
    // Call the read-only function to get the audit info.
    const auditInfo = simnet.callReadOnlyFn(
      "proof-of-audit",
      "get-audit-info",
      [Cl.buffer(existingHash)],
      deployer,
    );

    // The result should be (some {block-height: u2}).
    expect(auditInfo.result).toBeSome(Cl.tuple({ "block-height": Cl.uint(2) }));

    // Act & Assert (Non-Existing Hash):
    // Call the read-only function for a hash that was never anchored.
    const noInfo = simnet.callReadOnlyFn(
      "proof-of-audit",
      "get-audit-info",
      [Cl.buffer(nonExistingHash)],
      deployer,
    );

    // The result should be (none).
    expect(noInfo.result).toBeNone();
  });
});
