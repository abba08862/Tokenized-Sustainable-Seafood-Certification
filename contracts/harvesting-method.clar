;; Harvesting Method Contract
;; Records fishing or aquaculture techniques

(define-data-var admin principal tx-sender)

;; Data structure for harvesting methods
(define-map harvesting-methods
  { method-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    sustainability-score: uint,
    approved: bool
  }
)

;; Counter for method IDs
(define-data-var method-id-counter uint u0)

;; Data structure for producer harvesting records
(define-map harvesting-records
  { record-id: uint }
  {
    producer-id: uint,
    method-id: uint,
    timestamp: uint,
    location: (string-ascii 100),
    quantity: uint,
    notes: (string-ascii 500)
  }
)

;; Counter for record IDs
(define-data-var record-id-counter uint u0)

;; Register a new harvesting method
(define-public (register-method (name (string-ascii 100)) (description (string-ascii 500)) (sustainability-score uint))
  (let
    ((new-id (+ (var-get method-id-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (var-set method-id-counter new-id)
      (map-set harvesting-methods
        { method-id: new-id }
        {
          name: name,
          description: description,
          sustainability-score: sustainability-score,
          approved: false
        }
      )
      (ok new-id)
    )
  )
)

;; Approve a harvesting method
(define-public (approve-method (method-id uint))
  (let
    ((method-data (unwrap! (map-get? harvesting-methods { method-id: method-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set harvesting-methods
        { method-id: method-id }
        (merge method-data { approved: true })
      )
      (ok true)
    )
  )
)

;; Record a harvesting event
(define-public (record-harvesting (producer-id uint) (method-id uint) (location (string-ascii 100)) (quantity uint) (notes (string-ascii 500)))
  (let
    ((new-id (+ (var-get record-id-counter) u1))
     (method-data (unwrap! (map-get? harvesting-methods { method-id: method-id }) (err u404))))
    (begin
      ;; Check if the method is approved
      (asserts! (get approved method-data) (err u401))
      (var-set record-id-counter new-id)
      (map-set harvesting-records
        { record-id: new-id }
        {
          producer-id: producer-id,
          method-id: method-id,
          timestamp: block-height,
          location: location,
          quantity: quantity,
          notes: notes
        }
      )
      (ok new-id)
    )
  )
)

;; Get harvesting method information
(define-read-only (get-method (method-id uint))
  (map-get? harvesting-methods { method-id: method-id })
)

;; Get harvesting record information
(define-read-only (get-record (record-id uint))
  (map-get? harvesting-records { record-id: record-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
