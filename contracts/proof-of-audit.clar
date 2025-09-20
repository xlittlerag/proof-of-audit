;; proof-of-audit.clar
;;
;; This contract allows the audit firm to store a 32-byte hash (e.g., SHA256) of the audit report.
;; Storing the hash creates an immutable, timestamped proof that a piece of data existed
;; at the time the transaction was confirmed.

;; --- Data Storage ---

;; The key is a 32-byte buffer, which is the standard size for a SHA256 hash.
(define-map proof-of-audit (buff 32) {block-height: uint})


;; --- Constants and Errors ---

(define-constant DEPLOYER tx-sender)
(define-constant ERR-HASH-ALREADY-EXISTS (err u100))


;; --- Public Functions ---

;; @desc Anchors a hash on-chain, creating the proof of existence.
;; @param hash: The 32-byte hash of the data you want to prove existed.
;; @returns (response bool uint) - A success response if the hash is anchored,
;; or an error if the hash has already been recorded.
(define-public (anchor-hash (hash (buff 32)))
  (begin
    ;; Check the caller is the audit firm.
    (asserts! (is-eq DEPLOYER contract-caller) ERR-HASH-ALREADY-EXISTS)

    ;; Check if the hash has already been stored in the map.
    (asserts! (is-none (map-get? proof-of-audit hash)) ERR-HASH-ALREADY-EXISTS)

    ;; If the hash does not exist, set it in the map.
    ;; The value is a tuple containing the current block height.
    (map-set proof-of-audit hash
      {
        block-height: burn-block-height
      }
    )

    ;; Return a success response.
    (ok true)
  )
)


;; --- Read-Only Functions ---

;; @desc Retrieves the audit information for a given hash.
;; @param hash: The 32-byte hash to look up.
;; @returns (optional {block-height: uint})
(define-read-only (get-audit-info (hash (buff 32)))
  (map-get? proof-of-audit hash)
)

