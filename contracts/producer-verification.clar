;; Producer Verification Contract
;; Validates legitimate seafood sources

(define-data-var admin principal tx-sender)

;; Data structure for producer information
(define-map producers
  { producer-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    license-number: (string-ascii 50),
    verified: bool
  }
)

;; Counter for producer IDs
(define-data-var producer-id-counter uint u0)

;; Register a new producer
(define-public (register-producer (name (string-ascii 100)) (location (string-ascii 100)) (license-number (string-ascii 50)))
  (let
    ((new-id (+ (var-get producer-id-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (var-set producer-id-counter new-id)
      (map-set producers
        { producer-id: new-id }
        {
          name: name,
          location: location,
          license-number: license-number,
          verified: false
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a producer
(define-public (verify-producer (producer-id uint))
  (let
    ((producer-data (unwrap! (map-get? producers { producer-id: producer-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set producers
        { producer-id: producer-id }
        (merge producer-data { verified: true })
      )
      (ok true)
    )
  )
)

;; Get producer information
(define-read-only (get-producer (producer-id uint))
  (map-get? producers { producer-id: producer-id })
)

;; Check if a producer is verified
(define-read-only (is-producer-verified (producer-id uint))
  (default-to false (get verified (map-get? producers { producer-id: producer-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
