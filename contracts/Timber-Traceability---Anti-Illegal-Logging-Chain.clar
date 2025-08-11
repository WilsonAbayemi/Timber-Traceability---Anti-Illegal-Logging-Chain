

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-nft-not-found (err u102))
(define-constant err-already-blacklisted (err u103))
(define-constant err-not-blacklisted (err u104))
(define-constant err-invalid-coordinates (err u105))
(define-constant err-invalid-license (err u106))
(define-constant err-already-processed (err u107))
(define-constant err-vote-period-ended (err u108))
(define-constant err-already-voted (err u109))
(define-constant err-insufficient-votes (err u110))
(define-constant err-invalid-region (err u111))

(define-non-fungible-token timber-log uint)

(define-data-var last-token-id uint u0)
(define-data-var governance-threshold uint u3)
(define-data-var vote-period uint u1440)

(define-map timber-metadata
  uint
  {
    harvester: principal,
    gps-lat: int,
    gps-lon: int,
    harvest-license: (string-ascii 64),
    harvest-timestamp: uint,
    species: (string-ascii 32),
    processing-steps: (list 10 (string-ascii 64)),
    current-owner: principal,
    status: (string-ascii 16)
  }
)

(define-map blacklisted-harvesters principal bool)

(define-map governance-proposals
  uint
  {
    target: principal,
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    end-block: uint,
    executed: bool
  }
)

(define-map voter-records {proposal-id: uint, voter: principal} bool)

(define-data-var proposal-counter uint u0)

(define-map regional-analytics
  (string-ascii 32)
  {
    total-harvested: uint,
    total-processed: uint,
    total-finalized: uint,
    avg-processing-time: uint,
    sustainability-score: uint
  }
)

(define-map harvester-performance
  principal
  {
    total-logs: uint,
    avg-processing-time: uint,
    quality-rating: uint,
    last-harvest: uint,
    efficiency-score: uint
  }
)

(define-map species-tracking
  (string-ascii 32)
  {
    total-count: uint,
    regions: (list 10 (string-ascii 32)),
    avg-processing-time: uint
  }
)

(define-public (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-public (get-token-uri (token-id uint))
  (ok none)
)

(define-public (get-owner (token-id uint))
  (ok (nft-get-owner? timber-log token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (is-some (nft-get-owner? timber-log token-id)) err-nft-not-found)
    (try! (nft-transfer? timber-log token-id sender recipient))
    (match (map-get? timber-metadata token-id)
      metadata (map-set timber-metadata token-id 
        (merge metadata {current-owner: recipient}))
      false)
    (ok true)
  )
)

(define-public (harvest-timber 
  (gps-lat int) 
  (gps-lon int) 
  (harvest-license (string-ascii 64))
  (species (string-ascii 32))
  (region (string-ascii 32)))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
      (current-region-data (default-to {total-harvested: u0, total-processed: u0, total-finalized: u0, avg-processing-time: u0, sustainability-score: u100} 
                                      (map-get? regional-analytics region)))
      (current-harvester-data (default-to {total-logs: u0, avg-processing-time: u0, quality-rating: u100, last-harvest: u0, efficiency-score: u100} 
                                          (map-get? harvester-performance tx-sender)))
      (current-species-data (default-to {total-count: u0, regions: (list), avg-processing-time: u0} 
                                        (map-get? species-tracking species)))
    )
    (asserts! (not (default-to false (map-get? blacklisted-harvesters tx-sender))) err-already-blacklisted)
    (asserts! (and (>= gps-lat (* -90 1000000)) (<= gps-lat (* 90 1000000))) err-invalid-coordinates)
    (asserts! (and (>= gps-lon (* -180 1000000)) (<= gps-lon (* 180 1000000))) err-invalid-coordinates)
    (asserts! (> (len harvest-license) u0) err-invalid-license)
    (asserts! (> (len region) u0) err-invalid-region)
    
    (try! (nft-mint? timber-log token-id tx-sender))
    (map-set timber-metadata token-id {
      harvester: tx-sender,
      gps-lat: gps-lat,
      gps-lon: gps-lon,
      harvest-license: harvest-license,
      harvest-timestamp: stacks-block-height,
      species: species,
      processing-steps: (list),
      current-owner: tx-sender,
      status: "harvested"
    })
    
    (map-set regional-analytics region 
      (merge current-region-data {total-harvested: (+ (get total-harvested current-region-data) u1)}))
    
    (map-set harvester-performance tx-sender 
      (merge current-harvester-data {
        total-logs: (+ (get total-logs current-harvester-data) u1),
        last-harvest: stacks-block-height
      }))
    
    (let
      (
        (current-regions (get regions current-species-data))
        (updated-regions (if (is-none (index-of current-regions region))
                            (unwrap-panic (as-max-len? (append current-regions region) u10))
                            current-regions))
      )
      (map-set species-tracking species 
        (merge current-species-data {
          total-count: (+ (get total-count current-species-data) u1),
          regions: updated-regions
        }))
    )
    
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

(define-public (add-processing-step (token-id uint) (step (string-ascii 64)))
  (let
    (
      (metadata (unwrap! (map-get? timber-metadata token-id) err-nft-not-found))
      (current-steps (get processing-steps metadata))
    )
    (asserts! (is-eq (some tx-sender) (nft-get-owner? timber-log token-id)) err-not-token-owner)
    (asserts! (< (len current-steps) u10) err-already-processed)
    
    (map-set timber-metadata token-id 
      (merge metadata {
        processing-steps: (unwrap-panic (as-max-len? (append current-steps step) u10)),
        status: "processing"
      }))
    (ok true)
  )
)

(define-public (finalize-product (token-id uint) (region (string-ascii 32)))
  (let
    (
      (metadata (unwrap! (map-get? timber-metadata token-id) err-nft-not-found))
      (current-region-data (default-to {total-harvested: u0, total-processed: u0, total-finalized: u0, avg-processing-time: u0, sustainability-score: u100} 
                                      (map-get? regional-analytics region)))
      (processing-time (- stacks-block-height (get harvest-timestamp metadata)))
      (current-harvester-data (default-to {total-logs: u0, avg-processing-time: u0, quality-rating: u100, last-harvest: u0, efficiency-score: u100} 
                                          (map-get? harvester-performance (get harvester metadata))))
    )
    (asserts! (is-eq (some tx-sender) (nft-get-owner? timber-log token-id)) err-not-token-owner)
    (asserts! (> (len region) u0) err-invalid-region)
    
    (map-set timber-metadata token-id 
      (merge metadata {status: "final-product"}))
    
    (map-set regional-analytics region 
      (merge current-region-data {
        total-finalized: (+ (get total-finalized current-region-data) u1),
        avg-processing-time: (/ (+ (* (get avg-processing-time current-region-data) (get total-finalized current-region-data)) processing-time) 
                                (+ (get total-finalized current-region-data) u1))
      }))
    
    (let
      (
        (harvester-logs (get total-logs current-harvester-data))
        (new-avg-time (if (> harvester-logs u0)
                         (/ (+ (* (get avg-processing-time current-harvester-data) harvester-logs) processing-time) 
                            (+ harvester-logs u1))
                         processing-time))
      )
      (map-set harvester-performance (get harvester metadata)
        (merge current-harvester-data {
          avg-processing-time: new-avg-time,
          efficiency-score: (if (< processing-time u100) u100 (- u200 (/ processing-time u10)))
        }))
    )
    
    (ok true)
  )
)

(define-read-only (verify-timber-origin (token-id uint))
  (let
    (
      (metadata (unwrap! (map-get? timber-metadata token-id) err-nft-not-found))
      (harvester (get harvester metadata))
    )
    (ok {
      is-legitimate: (not (default-to false (map-get? blacklisted-harvesters harvester))),
      harvester: harvester,
      gps-coordinates: {lat: (get gps-lat metadata), lon: (get gps-lon metadata)},
      harvest-license: (get harvest-license metadata),
      harvest-timestamp: (get harvest-timestamp metadata),
      species: (get species metadata),
      processing-steps: (get processing-steps metadata),
      current-status: (get status metadata)
    })
  )
)

(define-public (propose-blacklist (target principal))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (end-block (+ stacks-block-height (var-get vote-period)))
    )
    (asserts! (not (default-to false (map-get? blacklisted-harvesters target))) err-already-blacklisted)
    
    (map-set governance-proposals proposal-id {
      target: target,
      proposer: tx-sender,
      votes-for: u0,
      votes-against: u0,
      end-block: end-block,
      executed: false
    })
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? governance-proposals proposal-id) err-nft-not-found))
      (voter-key {proposal-id: proposal-id, voter: tx-sender})
    )
    (asserts! (<= stacks-block-height (get end-block proposal)) err-vote-period-ended)
    (asserts! (is-none (map-get? voter-records voter-key)) err-already-voted)
    
    (map-set voter-records voter-key true)
    (if vote-for
      (map-set governance-proposals proposal-id 
        (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
      (map-set governance-proposals proposal-id 
        (merge proposal {votes-against: (+ (get votes-against proposal) u1)})))
    (ok true)
  )
)

(define-public (execute-blacklist-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? governance-proposals proposal-id) err-nft-not-found))
    )
    (asserts! (> stacks-block-height (get end-block proposal)) err-vote-period-ended)
    (asserts! (not (get executed proposal)) err-already-processed)
    (asserts! (>= (get votes-for proposal) (var-get governance-threshold)) err-insufficient-votes)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) err-insufficient-votes)
    
    (map-set blacklisted-harvesters (get target proposal) true)
    (map-set governance-proposals proposal-id 
      (merge proposal {executed: true}))
    (ok true)
  )
)

(define-public (remove-from-blacklist (target principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (default-to false (map-get? blacklisted-harvesters target)) err-not-blacklisted)
    (map-delete blacklisted-harvesters target)
    (ok true)
  )
)

(define-read-only (is-blacklisted (harvester principal))
  (default-to false (map-get? blacklisted-harvesters harvester))
)

(define-read-only (get-timber-metadata (token-id uint))
  (map-get? timber-metadata token-id)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? governance-proposals proposal-id)
)

(define-public (set-governance-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set governance-threshold new-threshold)
    (ok true)
  )
)

(define-public (set-vote-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set vote-period new-period)
    (ok true)
  )
)

(define-read-only (get-contract-info)
  {
    last-token-id: (var-get last-token-id),
    governance-threshold: (var-get governance-threshold),
    vote-period: (var-get vote-period),
    proposal-counter: (var-get proposal-counter)
  }
)

(define-read-only (get-regional-analytics (region (string-ascii 32)))
  (map-get? regional-analytics region)
)

(define-read-only (get-harvester-performance (harvester principal))
  (map-get? harvester-performance harvester)
)

(define-read-only (get-species-analytics (species (string-ascii 32)))
  (map-get? species-tracking species)
)

(define-read-only (calculate-sustainability-score (region (string-ascii 32)))
  (let
    (
      (region-data (map-get? regional-analytics region))
    )
    (match region-data
      data (let
        (
          (total-harvested (get total-harvested data))
          (total-finalized (get total-finalized data))
          (avg-time (get avg-processing-time data))
          (completion-rate (if (> total-harvested u0) (/ (* total-finalized u100) total-harvested) u0))
          (efficiency-bonus (if (< avg-time u50) u20 (if (< avg-time u100) u10 u0)))
        )
        (ok (+ completion-rate efficiency-bonus))
      )
      (ok u0)
    )
  )
)

(define-read-only (get-top-performing-harvesters (limit uint))
  (ok "Analytics feature requires off-chain indexing for complex queries")
)

(define-public (update-harvester-quality-rating (harvester principal) (rating uint))
  (let
    (
      (current-data (default-to {total-logs: u0, avg-processing-time: u0, quality-rating: u100, last-harvest: u0, efficiency-score: u100} 
                                (map-get? harvester-performance harvester)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= rating u100) err-invalid-coordinates)
    
    (map-set harvester-performance harvester 
      (merge current-data {quality-rating: rating}))
    (ok true)
  )
)

(define-public (update-regional-sustainability (region (string-ascii 32)) (score uint))
  (let
    (
      (current-data (default-to {total-harvested: u0, total-processed: u0, total-finalized: u0, avg-processing-time: u0, sustainability-score: u100} 
                                (map-get? regional-analytics region)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= score u100) err-invalid-coordinates)
    
    (map-set regional-analytics region 
      (merge current-data {sustainability-score: score}))
    (ok true)
  )
)
