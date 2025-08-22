;; Smart Inventory Management Contract
;; A comprehensive inventory management system with supplier tracking and access controls

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_STOCK (err u102))
(define-constant ERR_INVALID_QUANTITY (err u103))
(define-constant ERR_ITEM_EXISTS (err u104))
(define-constant ERR_SUPPLIER_NOT_FOUND (err u105))
(define-constant ERR_INVALID_PRICE (err u106))
(define-constant ERR_INVALID_THRESHOLD (err u107))
(define-constant ERR_INVALID_NAME (err u108))
(define-constant ERR_INVALID_DESCRIPTION (err u109))
(define-constant ERR_SAME_ITEM (err u110))
(define-constant ERR_INVALID_PRINCIPAL (err u111))

;; Data Variables
(define-data-var next-item-id uint u1)
(define-data-var next-supplier-id uint u1)

;; Data Maps
(define-map items
    { item-id: uint }
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        quantity: uint,
        min-threshold: uint,
        unit-price: uint,
        supplier-id: uint,
        created-at: uint,
        last-updated: uint
    }
)

(define-map suppliers
    { supplier-id: uint }
    {
        name: (string-ascii 100),
        contact: (string-ascii 100),
        is-active: bool,
        created-at: uint
    }
)

(define-map item-transactions
    { transaction-id: uint }
    {
        item-id: uint,
        transaction-type: (string-ascii 10), ;; "in" or "out"
        quantity: uint,
        timestamp: uint,
        performed-by: principal
    }
)

(define-map authorized-users principal bool)

(define-data-var next-transaction-id uint u1)

;; Authorization Functions
(define-private (is-authorized (user principal))
    (or 
        (is-eq user CONTRACT_OWNER)
        (default-to false (map-get? authorized-users user))
    )
)

(define-private (validate-principal (user principal))
    (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-public (authorize-user (user principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (validate-principal user) ERR_INVALID_PRINCIPAL)
        (ok (map-set authorized-users user true))
    )
)

(define-public (revoke-user (user principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (validate-principal user) ERR_INVALID_PRINCIPAL)
        (ok (map-delete authorized-users user))
    )
)

;; Validation Functions
(define-private (validate-string-length (str (string-ascii 200)) (min-len uint) (max-len uint))
    (and (>= (len str) min-len) (<= (len str) max-len))
)

(define-private (validate-supplier-name (name (string-ascii 100)))
    (validate-string-length name u1 u100)
)

(define-private (validate-supplier-contact (contact (string-ascii 100)))
    (validate-string-length contact u1 u100)
)

(define-private (validate-item-name (name (string-ascii 50)))
    (validate-string-length name u1 u50)
)

(define-private (validate-item-description (description (string-ascii 200)))
    (validate-string-length description u1 u200)
)

(define-private (validate-positive-uint (value uint))
    (> value u0)
)

(define-private (validate-non-negative-uint (value uint))
    (>= value u0)
)

(define-private (validate-supplier-id (supplier-id uint))
    (and 
        (> supplier-id u0)
        (< supplier-id (var-get next-supplier-id))
        (is-some (map-get? suppliers { supplier-id: supplier-id }))
    )
)

(define-private (validate-item-id (item-id uint))
    (and 
        (> item-id u0)
        (< item-id (var-get next-item-id))
        (is-some (map-get? items { item-id: item-id }))
    )
)

;; Supplier Management Functions
(define-public (add-supplier (name (string-ascii 100)) (contact (string-ascii 100)))
    (let ((supplier-id (var-get next-supplier-id)))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-supplier-name name) ERR_INVALID_NAME)
        (asserts! (validate-supplier-contact contact) ERR_INVALID_NAME)
        (map-set suppliers 
            { supplier-id: supplier-id }
            {
                name: name,
                contact: contact,
                is-active: true,
                created-at: block-height
            }
        )
        (var-set next-supplier-id (+ supplier-id u1))
        (ok supplier-id)
    )
)

(define-public (update-supplier (supplier-id uint) (name (string-ascii 100)) (contact (string-ascii 100)) (is-active bool))
    (let ((supplier (map-get? suppliers { supplier-id: supplier-id })))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-supplier-id supplier-id) ERR_SUPPLIER_NOT_FOUND)
        (asserts! (validate-supplier-name name) ERR_INVALID_NAME)
        (asserts! (validate-supplier-contact contact) ERR_INVALID_NAME)
        (map-set suppliers 
            { supplier-id: supplier-id }
            {
                name: name,
                contact: contact,
                is-active: is-active,
                created-at: (get created-at (unwrap-panic supplier))
            }
        )
        (ok true)
    )
)

(define-read-only (get-supplier (supplier-id uint))
    (map-get? suppliers { supplier-id: supplier-id })
)

;; Item Management Functions
(define-public (add-item 
    (name (string-ascii 50)) 
    (description (string-ascii 200)) 
    (initial-quantity uint) 
    (min-threshold uint) 
    (unit-price uint) 
    (supplier-id uint)
)
    (let ((item-id (var-get next-item-id)))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-item-name name) ERR_INVALID_NAME)
        (asserts! (validate-item-description description) ERR_INVALID_DESCRIPTION)
        (asserts! (validate-non-negative-uint initial-quantity) ERR_INVALID_QUANTITY)
        (asserts! (validate-non-negative-uint min-threshold) ERR_INVALID_THRESHOLD)
        (asserts! (validate-positive-uint unit-price) ERR_INVALID_PRICE)
        (asserts! (validate-supplier-id supplier-id) ERR_SUPPLIER_NOT_FOUND)
        
        (map-set items 
            { item-id: item-id }
            {
                name: name,
                description: description,
                quantity: initial-quantity,
                min-threshold: min-threshold,
                unit-price: unit-price,
                supplier-id: supplier-id,
                created-at: block-height,
                last-updated: block-height
            }
        )
        
        ;; Record initial stock if quantity > 0
        (if (> initial-quantity u0)
            (record-transaction item-id "in" initial-quantity)
            true
        )
        
        (var-set next-item-id (+ item-id u1))
        (ok item-id)
    )
)

(define-public (update-item 
    (item-id uint) 
    (name (string-ascii 50)) 
    (description (string-ascii 200)) 
    (min-threshold uint) 
    (unit-price uint)
)
    (let ((item (map-get? items { item-id: item-id })))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-item-id item-id) ERR_NOT_FOUND)
        (asserts! (validate-item-name name) ERR_INVALID_NAME)
        (asserts! (validate-item-description description) ERR_INVALID_DESCRIPTION)
        (asserts! (validate-non-negative-uint min-threshold) ERR_INVALID_THRESHOLD)
        (asserts! (validate-positive-uint unit-price) ERR_INVALID_PRICE)
        
        (let ((current-item (unwrap-panic item)))
            (map-set items 
                { item-id: item-id }
                {
                    name: name,
                    description: description,
                    quantity: (get quantity current-item),
                    min-threshold: min-threshold,
                    unit-price: unit-price,
                    supplier-id: (get supplier-id current-item),
                    created-at: (get created-at current-item),
                    last-updated: block-height
                }
            )
        )
        (ok true)
    )
)

(define-read-only (get-item (item-id uint))
    (map-get? items { item-id: item-id })
)

;; Stock Management Functions
(define-public (add-stock (item-id uint) (quantity uint))
    (let ((item (map-get? items { item-id: item-id })))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-item-id item-id) ERR_NOT_FOUND)
        (asserts! (validate-positive-uint quantity) ERR_INVALID_QUANTITY)
        
        (let ((current-item (unwrap-panic item)))
            (map-set items 
                { item-id: item-id }
                (merge current-item {
                    quantity: (+ (get quantity current-item) quantity),
                    last-updated: block-height
                })
            )
            (record-transaction item-id "in" quantity)
        )
        (ok true)
    )
)

(define-public (remove-stock (item-id uint) (quantity uint))
    (let ((item (map-get? items { item-id: item-id })))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-item-id item-id) ERR_NOT_FOUND)
        (asserts! (validate-positive-uint quantity) ERR_INVALID_QUANTITY)
        
        (let ((current-item (unwrap-panic item)))
            (asserts! (>= (get quantity current-item) quantity) ERR_INSUFFICIENT_STOCK)
            (map-set items 
                { item-id: item-id }
                (merge current-item {
                    quantity: (- (get quantity current-item) quantity),
                    last-updated: block-height
                })
            )
            (record-transaction item-id "out" quantity)
        )
        (ok true)
    )
)

(define-public (transfer-stock (from-item-id uint) (to-item-id uint) (quantity uint))
    (let (
        (from-item (map-get? items { item-id: from-item-id }))
        (to-item (map-get? items { item-id: to-item-id }))
    )
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-item-id from-item-id) ERR_NOT_FOUND)
        (asserts! (validate-item-id to-item-id) ERR_NOT_FOUND)
        (asserts! (validate-positive-uint quantity) ERR_INVALID_QUANTITY)
        (asserts! (not (is-eq from-item-id to-item-id)) ERR_SAME_ITEM)
        
        (let (
            (current-from-item (unwrap-panic from-item))
            (current-to-item (unwrap-panic to-item))
        )
            (asserts! (>= (get quantity current-from-item) quantity) ERR_INSUFFICIENT_STOCK)
            
            ;; Update from item
            (map-set items 
                { item-id: from-item-id }
                (merge current-from-item {
                    quantity: (- (get quantity current-from-item) quantity),
                    last-updated: block-height
                })
            )
            
            ;; Update to item
            (map-set items 
                { item-id: to-item-id }
                (merge current-to-item {
                    quantity: (+ (get quantity current-to-item) quantity),
                    last-updated: block-height
                })
            )
            
            ;; Record transactions
            (record-transaction from-item-id "out" quantity)
            (record-transaction to-item-id "in" quantity)
        )
        (ok true)
    )
)

;; Transaction Recording
(define-private (record-transaction (item-id uint) (transaction-type (string-ascii 10)) (quantity uint))
    (let ((transaction-id (var-get next-transaction-id)))
        (map-set item-transactions
            { transaction-id: transaction-id }
            {
                item-id: item-id,
                transaction-type: transaction-type,
                quantity: quantity,
                timestamp: block-height,
                performed-by: tx-sender
            }
        )
        (var-set next-transaction-id (+ transaction-id u1))
        true
    )
)

(define-read-only (get-transaction (transaction-id uint))
    (map-get? item-transactions { transaction-id: transaction-id })
)

;; Inventory Analysis Functions
(define-read-only (is-below-threshold (item-id uint))
    (match (map-get? items { item-id: item-id })
        item (< (get quantity item) (get min-threshold item))
        false
    )
)

(define-read-only (get-stock-level (item-id uint))
    (match (map-get? items { item-id: item-id })
        item (some (get quantity item))
        none
    )
)

(define-read-only (calculate-inventory-value (item-id uint))
    (match (map-get? items { item-id: item-id })
        item (some (* (get quantity item) (get unit-price item)))
        none
    )
)

;; Utility Functions
(define-read-only (get-next-item-id)
    (var-get next-item-id)
)

(define-read-only (get-next-supplier-id)
    (var-get next-supplier-id)
)

(define-read-only (get-next-transaction-id)
    (var-get next-transaction-id)
)

(define-read-only (is-user-authorized (user principal))
    (is-authorized user)
)

;; Batch Operations
(define-public (batch-update-thresholds (updates (list 10 { item-id: uint, min-threshold: uint })))
    (begin
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (ok (map update-single-threshold updates))
    )
)

(define-private (update-single-threshold (update { item-id: uint, min-threshold: uint }))
    (let ((item-id (get item-id update))
          (min-threshold (get min-threshold update))
          (item (map-get? items { item-id: item-id })))
        (if (and (validate-item-id item-id) (validate-non-negative-uint min-threshold) (is-some item))
            (let ((current-item (unwrap-panic item)))
                (map-set items 
                    { item-id: item-id }
                    (merge current-item {
                        min-threshold: min-threshold,
                        last-updated: block-height
                    })
                )
                true
            )
            false
        )
    )
)

;; Emergency Functions
(define-public (emergency-stock-adjustment (item-id uint) (new-quantity uint))
    (let ((item (map-get? items { item-id: item-id })))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (validate-item-id item-id) ERR_NOT_FOUND)
        (asserts! (validate-non-negative-uint new-quantity) ERR_INVALID_QUANTITY)
        
        (let ((current-item (unwrap-panic item)))
            (map-set items 
                { item-id: item-id }
                (merge current-item {
                    quantity: new-quantity,
                    last-updated: block-height
                })
            )
            (record-transaction item-id "adjust" new-quantity)
        )
        (ok true)
    )
)