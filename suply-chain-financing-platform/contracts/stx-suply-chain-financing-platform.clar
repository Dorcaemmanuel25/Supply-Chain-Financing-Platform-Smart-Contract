;; Supply Chain Financing Platform Smart Contract
;; A decentralized platform for supply chain working capital solutions

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-invalid-rate (err u104))
(define-constant err-supplier-not-approved (err u105))
(define-constant err-invoice-expired (err u106))
(define-constant err-financing-exists (err u107))
(define-constant err-insufficient-credit (err u108))
(define-constant err-invalid-terms (err u109))
(define-constant err-buyer-not-verified (err u110))

;; Data Variables
(define-data-var next-invoice-id uint u1)
(define-data-var next-financing-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var min-credit-rating uint u600)
(define-data-var max-financing-ratio uint u8500) ;; 85% in basis points

;; Data Maps

;; Company registration and information
(define-map companies principal {
    name: (string-ascii 100),
    company-type: (string-ascii 20), ;; "buyer", "supplier", "financier"
    registration-number: (string-ascii 50),
    is-verified: bool,
    credit-rating: uint,
    total-volume: uint,
    success-rate: uint,
    registered-at: uint,
    contact-info: (string-ascii 200),
    credit-limit: uint
})

;; Invoice records for supply chain financing
(define-map invoices uint {
    supplier: principal,
    buyer: principal,
    invoice-number: (string-ascii 50),
    invoice-amount: uint,
    due-date: uint,
    payment-terms: uint, ;; Days
    goods-description: (string-ascii 200),
    status: (string-ascii 20), ;; "pending", "approved", "financed", "paid"
    buyer-approval: bool,
    discount-rate: uint, ;; Annual rate in basis points
    created-at: uint,
    approved-at: (optional uint),
    financed-at: (optional uint)
})

;; Financing arrangements
(define-map financing-requests uint {
    invoice-id: uint,
    supplier: principal,
    financier: principal,
    requested-amount: uint,
    offered-rate: uint, ;; Annual interest rate in basis points
    financing-fee: uint,
    early-payment-discount: uint,
    net-payment: uint,
    financing-term: uint, ;; Days until buyer payment
    status: (string-ascii 20), ;; "requested", "approved", "funded", "repaid"
    request-date: uint,
    funding-date: (optional uint),
    repayment-date: (optional uint)
})

;; Buyer payment commitments
(define-map payment-commitments {buyer: principal, invoice-id: uint} {
    commitment-amount: uint,
    commitment-date: uint,
    payment-guarantee: bool,
    approved-financiers: (list 10 principal),
    created-at: uint
})

;; Financial institution profiles
(define-map financiers principal {
    institution-name: (string-ascii 100),
    license-number: (string-ascii 50),
    is-approved: bool,
    funding-capacity: uint,
    min-financing-amount: uint,
    max-financing-amount: uint,
    standard-rate: uint, ;; Basis points
    reputation-score: uint,
    total-financed: uint,
    active-deals: uint,
    registered-at: uint
})

;; Transaction history and analytics
(define-map transaction-history uint {
    transaction-type: (string-ascii 30), ;; "invoice-created", "financing-approved", etc.
    participants: (list 3 principal),
    amount: uint,
    timestamp: uint,
    reference-id: uint
})

;; Platform statistics
(define-map platform-stats (string-ascii 30) uint)

;; Private Functions

;; Calculate financing discount based on early payment
(define-private (calculate-early-payment-discount 
    (invoice-amount uint) 
    (annual-rate uint) 
    (days-early uint))
    (let ((daily-rate (/ annual-rate u36500))) ;; Convert annual rate to daily
        (/ (* invoice-amount daily-rate days-early) u10000)))

;; Calculate net payment amount after fees and discounts
(define-private (calculate-net-payment 
    (invoice-amount uint) 
    (financing-rate uint) 
    (platform-fee uint) 
    (days-to-payment uint))
    (let ((interest-cost (calculate-early-payment-discount invoice-amount financing-rate days-to-payment))
          (platform-cost (/ (* invoice-amount platform-fee) u10000)))
        (- invoice-amount (+ interest-cost platform-cost))))

;; Validate credit worthiness
(define-private (check-credit-eligibility (company principal) (requested-amount uint))
    (match (map-get? companies company)
        company-info (and 
            (get is-verified company-info)
            (>= (get credit-rating company-info) (var-get min-credit-rating))
            (<= requested-amount (get credit-limit company-info)))
        false))

;; Calculate financing risk score
(define-private (calculate-risk-score (supplier principal) (buyer principal) (amount uint))
    (let ((supplier-info (unwrap-panic (map-get? companies supplier)))
          (buyer-info (unwrap-panic (map-get? companies buyer))))
        (+ (* (get credit-rating supplier-info) u40) ;; 40% weight
           (* (get credit-rating buyer-info) u40)     ;; 40% weight
           (* (get success-rate supplier-info) u20)))) ;; 20% weight

;; Update platform statistics
(define-private (update-platform-stat (key (string-ascii 30)) (increment uint))
    (let ((current-value (default-to u0 (map-get? platform-stats key))))
        (map-set platform-stats key (+ current-value increment))))

;; Log transaction for audit trail
(define-private (log-transaction 
    (tx-type (string-ascii 30)) 
    (participants (list 3 principal)) 
    (amount uint) 
    (ref-id uint))
    (let ((tx-id (+ (default-to u0 (map-get? platform-stats "total-transactions")) u1)))
        (map-set transaction-history tx-id {
            transaction-type: tx-type,
            participants: participants,
            amount: amount,
            timestamp: stacks-block-height,
            reference-id: ref-id
        })
        (update-platform-stat "total-transactions" u1)))

;; Public Functions

;; Register company on the platform
(define-public (register-company 
    (name (string-ascii 100))
    (company-type (string-ascii 20))
    (registration-number (string-ascii 50))
    (contact-info (string-ascii 200))
    (credit-limit uint))
    (begin
        (asserts! (or (is-eq company-type "buyer") 
                     (is-eq company-type "supplier") 
                     (is-eq company-type "financier")) err-invalid-terms)
        
        (map-set companies tx-sender {
            name: name,
            company-type: company-type,
            registration-number: registration-number,
            is-verified: false,
            credit-rating: u500, ;; Default rating
            total-volume: u0,
            success-rate: u100,
            registered-at: stacks-block-height,
            contact-info: contact-info,
            credit-limit: credit-limit
        })
        
        (update-platform-stat "total-companies" u1)
        (log-transaction "company-registered" (list tx-sender) u0 u0)
        (ok true)))

;; Verify company (admin only)
(define-public (verify-company (company principal) (credit-rating uint))
    (let ((company-info (unwrap! (map-get? companies company) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (and (>= credit-rating u300) (<= credit-rating u850)) err-invalid-terms)
        
        (map-set companies company 
            (merge company-info {
                is-verified: true, 
                credit-rating: credit-rating
            }))
        (ok true)))

;; Register financial institution
(define-public (register-financier
    (institution-name (string-ascii 100))
    (license-number (string-ascii 50))
    (funding-capacity uint)
    (min-amount uint)
    (max-amount uint)
    (standard-rate uint))
    (begin
        (asserts! (> funding-capacity u0) err-invalid-amount)
        (asserts! (> max-amount min-amount) err-invalid-amount)
        (asserts! (> standard-rate u0) err-invalid-rate)
        
        (map-set financiers tx-sender {
            institution-name: institution-name,
            license-number: license-number,
            is-approved: false,
            funding-capacity: funding-capacity,
            min-financing-amount: min-amount,
            max-financing-amount: max-amount,
            standard-rate: standard-rate,
            reputation-score: u100,
            total-financed: u0,
            active-deals: u0,
            registered-at: stacks-block-height
        })
        
        (update-platform-stat "total-financiers" u1)
        (ok true)))

;; Create invoice for financing
(define-public (create-invoice
    (buyer principal)
    (invoice-number (string-ascii 50))
    (invoice-amount uint)
    (payment-terms uint)
    (goods-description (string-ascii 200)))
    (let ((invoice-id (var-get next-invoice-id)))
        
        (asserts! (> invoice-amount u0) err-invalid-amount)
        (asserts! (> payment-terms u0) err-invalid-terms)
        (asserts! (check-credit-eligibility tx-sender invoice-amount) err-insufficient-credit)
        
        (map-set invoices invoice-id {
            supplier: tx-sender,
            buyer: buyer,
            invoice-number: invoice-number,
            invoice-amount: invoice-amount,
            due-date: (+ stacks-block-height (* payment-terms u144)), ;; Approximate blocks per day
            payment-terms: payment-terms,
            goods-description: goods-description,
            status: "pending",
            buyer-approval: false,
            discount-rate: u0,
            created-at: stacks-block-height,
            approved-at: none,
            financed-at: none
        })
        
        (var-set next-invoice-id (+ invoice-id u1))
        (update-platform-stat "total-invoices" u1)
        (log-transaction "invoice-created" (list tx-sender buyer) invoice-amount invoice-id)
        (ok invoice-id)))

;; Buyer approves invoice for financing
(define-public (approve-invoice (invoice-id uint))
    (let ((invoice (unwrap! (map-get? invoices invoice-id) err-not-found)))
        (asserts! (is-eq (get buyer invoice) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status invoice) "pending") err-invalid-terms)
        
        (map-set invoices invoice-id 
            (merge invoice {
                status: "approved",
                buyer-approval: true,
                approved-at: (some stacks-block-height)
            }))
        
        ;; Create payment commitment
        (map-set payment-commitments {buyer: tx-sender, invoice-id: invoice-id} {
            commitment-amount: (get invoice-amount invoice),
            commitment-date: (get due-date invoice),
            payment-guarantee: true,
            approved-financiers: (list),
            created-at: stacks-block-height
        })
        
        (log-transaction "invoice-approved" (list tx-sender (get supplier invoice)) (get invoice-amount invoice) invoice-id)
        (ok true)))

;; Request financing for approved invoice
(define-public (request-financing (invoice-id uint) (financier principal) (requested-amount uint))
    (let ((invoice (unwrap! (map-get? invoices invoice-id) err-not-found))
          (financier-info (unwrap! (map-get? financiers financier) err-not-found))
          (financing-id (var-get next-financing-id)))
        
        (asserts! (is-eq (get supplier invoice) tx-sender) err-unauthorized)
        (asserts! (get buyer-approval invoice) err-unauthorized)
        (asserts! (get is-approved financier-info) err-supplier-not-approved)
        (asserts! (and (>= requested-amount (get min-financing-amount financier-info))
                      (<= requested-amount (get max-financing-amount financier-info))) err-invalid-amount)
        
        (let ((financing-fee (/ (* requested-amount (get standard-rate financier-info)) u10000))
              (net-payment (calculate-net-payment 
                          requested-amount 
                          (get standard-rate financier-info) 
                          (var-get platform-fee-rate)
                          (get payment-terms invoice))))
            
            (map-set financing-requests financing-id {
                invoice-id: invoice-id,
                supplier: tx-sender,
                financier: financier,
                requested-amount: requested-amount,
                offered-rate: (get standard-rate financier-info),
                financing-fee: financing-fee,
                early-payment-discount: (calculate-early-payment-discount 
                                       requested-amount 
                                       (get standard-rate financier-info)
                                       (get payment-terms invoice)),
                net-payment: net-payment,
                financing-term: (get payment-terms invoice),
                status: "requested",
                request-date: stacks-block-height,
                funding-date: none,
                repayment-date: none
            }))
        
        (var-set next-financing-id (+ financing-id u1))
        (update-platform-stat "total-financing-requests" u1)
        (log-transaction "financing-requested" (list tx-sender financier) requested-amount financing-id)
        (ok financing-id)))

;; Financier approves and funds the request
(define-public (approve-financing (financing-id uint))
    (let ((financing (unwrap! (map-get? financing-requests financing-id) err-not-found))
          (invoice (unwrap! (map-get? invoices (get invoice-id financing)) err-not-found)))
        
        (asserts! (is-eq (get financier financing) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status financing) "requested") err-invalid-terms)
        
        ;; Update financing status
        (map-set financing-requests financing-id
            (merge financing {
                status: "funded",
                funding-date: (some stacks-block-height)
            }))
        
        ;; Update invoice status
        (map-set invoices (get invoice-id financing)
            (merge invoice {
                status: "financed",
                financed-at: (some stacks-block-height)
            }))
        
        ;; Update financier statistics
        (let ((financier-info (unwrap-panic (map-get? financiers tx-sender))))
            (map-set financiers tx-sender
                (merge financier-info {
                    total-financed: (+ (get total-financed financier-info) (get requested-amount financing)),
                    active-deals: (+ (get active-deals financier-info) u1)
                })))
        
        (update-platform-stat "total-funded-amount" (get requested-amount financing))
        (log-transaction "financing-approved" 
            (list tx-sender (get supplier financing)) 
            (get requested-amount financing) 
            financing-id)
        (ok true)))

;; Process buyer payment (when due date arrives)
(define-public (process-payment (financing-id uint))
    (let ((financing (unwrap! (map-get? financing-requests financing-id) err-not-found))
          (invoice (unwrap! (map-get? invoices (get invoice-id financing)) err-not-found)))
        
        (asserts! (is-eq (get buyer invoice) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status financing) "funded") err-invalid-terms)
        (asserts! (>= stacks-block-height (get due-date invoice)) err-invalid-terms)
        
        ;; Update financing status
        (map-set financing-requests financing-id
            (merge financing {
                status: "repaid",
                repayment-date: (some stacks-block-height)
            }))
        
        ;; Update invoice status
        (map-set invoices (get invoice-id financing)
            (merge invoice {status: "paid"}))
        
        ;; Update financier active deals
        (let ((financier-info (unwrap-panic (map-get? financiers (get financier financing)))))
            (map-set financiers (get financier financing)
                (merge financier-info {
                    active-deals: (- (get active-deals financier-info) u1)
                })))
        
        (log-transaction "payment-processed" 
            (list tx-sender (get supplier financing) (get financier financing)) 
            (get requested-amount financing) 
            financing-id)
        (ok true)))

;; Admin function to set platform parameters
(define-public (set-platform-parameters (min-credit uint) (max-ratio uint) (fee-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set min-credit-rating min-credit)
        (var-set max-financing-ratio max-ratio)
        (var-set platform-fee-rate fee-rate)
        (ok true)))

;; Read-Only Functions

(define-read-only (get-company-info (company principal))
    (map-get? companies company))

(define-read-only (get-invoice (invoice-id uint))
    (map-get? invoices invoice-id))

(define-read-only (get-financing-request (financing-id uint))
    (map-get? financing-requests financing-id))

(define-read-only (get-financier-info (financier principal))
    (map-get? financiers financier))

(define-read-only (get-payment-commitment (buyer principal) (invoice-id uint))
    (map-get? payment-commitments {buyer: buyer, invoice-id: invoice-id}))

(define-read-only (calculate-financing-cost (amount uint) (rate uint) (days uint))
    (let ((interest (calculate-early-payment-discount amount rate days))
          (platform-fee (/ (* amount (var-get platform-fee-rate)) u10000)))
        {
            interest-cost: interest,
            platform-fee: platform-fee,
            total-cost: (+ interest platform-fee),
            net-amount: (- amount (+ interest platform-fee))
        }))

(define-read-only (get-platform-statistics)
    {
        total-companies: (default-to u0 (map-get? platform-stats "total-companies")),
        total-invoices: (default-to u0 (map-get? platform-stats "total-invoices")),
        total-financiers: (default-to u0 (map-get? platform-stats "total-financiers")),
        total-financing-requests: (default-to u0 (map-get? platform-stats "total-financing-requests")),
        total-funded-amount: (default-to u0 (map-get? platform-stats "total-funded-amount")),
        total-transactions: (default-to u0 (map-get? platform-stats "total-transactions")),
        min-credit-rating: (var-get min-credit-rating),
        max-financing-ratio: (var-get max-financing-ratio),
        platform-fee-rate: (var-get platform-fee-rate)
    })

;; Check financing eligibility
(define-read-only (check-financing-eligibility 
    (supplier principal) 
    (invoice-amount uint) 
    (financier principal))
    (match (map-get? companies supplier)
        supplier-info (match (map-get? financiers financier)
            financier-info (ok {
                eligible: (and 
                    (get is-verified supplier-info)
                    (get is-approved financier-info)
                    (>= (get credit-rating supplier-info) (var-get min-credit-rating))
                    (>= invoice-amount (get min-financing-amount financier-info))
                    (<= invoice-amount (get max-financing-amount financier-info))),
                estimated-cost: (calculate-early-payment-discount 
                               invoice-amount 
                               (get standard-rate financier-info) 
                               u30), ;; 30 days default
                net-funding: (calculate-net-payment 
                            invoice-amount 
                            (get standard-rate financier-info) 
                            (var-get platform-fee-rate) 
                            u30)
            })
            (err "Financier not found"))
        (err "Supplier not found")))

;; Get best financing rates for an amount
(define-read-only (get-competitive-financing-rates (amount uint))
    {
        message: "Use off-chain service to compare rates from all approved financiers",
        suggestion: "Query check-financing-eligibility for each financier"
    })

;; Calculate ROI for financiers
(define-read-only (calculate-financier-roi (financing-id uint))
    (match (map-get? financing-requests financing-id)
        financing (let ((investment (get requested-amount financing))
                       (return (+ investment (get financing-fee financing)))
                       (days (get financing-term financing)))
            (ok {
                investment-amount: investment,
                return-amount: return,
                profit: (get financing-fee financing),
                roi-percentage: (/ (* (get financing-fee financing) u10000) investment),
                annualized-return: (/ (* (get financing-fee financing) u36500) (* investment days))
            }))
        (err "Financing request not found")))

;; Emergency pause function
(define-public (emergency-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; Implementation for emergency pause
        (ok true)))