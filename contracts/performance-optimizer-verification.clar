;; Performance Optimizer Verification Contract
;; Validates and manages performance optimizers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_OPTIMIZER_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map optimizers
  { optimizer-id: uint }
  {
    principal: principal,
    name: (string-ascii 50),
    certification-level: uint,
    specialization: (string-ascii 100),
    verified: bool,
    verification-date: uint,
    performance-score: uint
  }
)

(define-map optimizer-credentials
  { optimizer-id: uint }
  {
    certifications: (list 10 (string-ascii 50)),
    experience-years: uint,
    success-rate: uint,
    projects-completed: uint
  }
)

(define-data-var next-optimizer-id uint u1)

;; Register new optimizer
(define-public (register-optimizer
  (name (string-ascii 50))
  (certification-level uint)
  (specialization (string-ascii 100))
  (certifications (list 10 (string-ascii 50)))
  (experience-years uint))
  (let ((optimizer-id (var-get next-optimizer-id)))
    (map-set optimizers
      { optimizer-id: optimizer-id }
      {
        principal: tx-sender,
        name: name,
        certification-level: certification-level,
        specialization: specialization,
        verified: false,
        verification-date: u0,
        performance-score: u0
      }
    )
    (map-set optimizer-credentials
      { optimizer-id: optimizer-id }
      {
        certifications: certifications,
        experience-years: experience-years,
        success-rate: u0,
        projects-completed: u0
      }
    )
    (var-set next-optimizer-id (+ optimizer-id u1))
    (ok optimizer-id)
  )
)

;; Verify optimizer (admin only)
(define-public (verify-optimizer (optimizer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? optimizers { optimizer-id: optimizer-id })
      optimizer-data
      (begin
        (asserts! (not (get verified optimizer-data)) ERR_ALREADY_VERIFIED)
        (map-set optimizers
          { optimizer-id: optimizer-id }
          (merge optimizer-data {
            verified: true,
            verification-date: block-height
          })
        )
        (ok true)
      )
      ERR_OPTIMIZER_NOT_FOUND
    )
  )
)

;; Update performance score
(define-public (update-performance-score (optimizer-id uint) (score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? optimizers { optimizer-id: optimizer-id })
      optimizer-data
      (begin
        (map-set optimizers
          { optimizer-id: optimizer-id }
          (merge optimizer-data { performance-score: score })
        )
        (ok true)
      )
      ERR_OPTIMIZER_NOT_FOUND
    )
  )
)

;; Get optimizer details
(define-read-only (get-optimizer (optimizer-id uint))
  (map-get? optimizers { optimizer-id: optimizer-id })
)

;; Get optimizer credentials
(define-read-only (get-optimizer-credentials (optimizer-id uint))
  (map-get? optimizer-credentials { optimizer-id: optimizer-id })
)

;; Check if optimizer is verified
(define-read-only (is-optimizer-verified (optimizer-id uint))
  (match (map-get? optimizers { optimizer-id: optimizer-id })
    optimizer-data (get verified optimizer-data)
    false
  )
)
