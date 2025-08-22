# Smart Inventory Management Contract

A comprehensive blockchain-based inventory management system built on the Stacks blockchain using Clarity smart contracts. This contract provides secure, transparent, and efficient inventory tracking with supplier management and access controls.

## Features

### Core Functionality
- **Item Management**: Add, update, and track inventory items with detailed metadata
- **Stock Operations**: Add, remove, and transfer stock between items
- **Supplier Management**: Maintain supplier information and relationships
- **Transaction History**: Complete audit trail of all inventory movements
- **Access Control**: Role-based permissions with owner and authorized user levels

### Advanced Features
- **Low Stock Alerts**: Automatic threshold monitoring for inventory replenishment
- **Inventory Valuation**: Calculate total value of stock holdings
- **Batch Operations**: Update multiple item thresholds simultaneously
- **Emergency Controls**: Owner-only emergency stock adjustments
- **Data Validation**: Comprehensive input validation and error handling

## Contract Structure

### Data Maps
- `items`: Stores item details including name, quantity, pricing, and supplier information
- `suppliers`: Maintains supplier contact information and status
- `item-transactions`: Records all stock movements with timestamps and user attribution
- `authorized-users`: Manages user access permissions

### Error Codes
- `ERR_UNAUTHORIZED (100)`: User lacks required permissions
- `ERR_NOT_FOUND (101)`: Requested item does not exist
- `ERR_INSUFFICIENT_STOCK (102)`: Not enough stock for requested operation
- `ERR_INVALID_QUANTITY (103)`: Invalid quantity specified
- `ERR_ITEM_EXISTS (104)`: Item already exists
- `ERR_SUPPLIER_NOT_FOUND (105)`: Referenced supplier does not exist
- `ERR_INVALID_PRICE (106)`: Invalid price value
- `ERR_INVALID_THRESHOLD (107)`: Invalid threshold value
- `ERR_INVALID_NAME (108)`: Invalid name format
- `ERR_INVALID_DESCRIPTION (109)`: Invalid description format
- `ERR_SAME_ITEM (110)`: Cannot transfer to same item
- `ERR_INVALID_PRINCIPAL (111)`: Invalid user principal

## Usage Guide

### Initial Setup

1. **Deploy Contract**: The deploying address becomes the contract owner
2. **Add Suppliers**: Create supplier records before adding items
3. **Authorize Users**: Grant access to additional users as needed

### Basic Operations

#### Supplier Management
```clarity
;; Add a new supplier
(contract-call? .inventory-contract add-supplier "Supplier Name" "contact@email.com")

;; Update supplier information
(contract-call? .inventory-contract update-supplier u1 "Updated Name" "new@email.com" true)

;; Get supplier details
(contract-call? .inventory-contract get-supplier u1)
```

#### Item Management
```clarity
;; Add new item
(contract-call? .inventory-contract add-item 
    "Product Name" 
    "Product description" 
    u100    ;; initial quantity
    u10     ;; minimum threshold
    u500    ;; unit price
    u1      ;; supplier ID
)

;; Update item details
(contract-call? .inventory-contract update-item u1 "New Name" "New description" u5 u600)

;; Get item information
(contract-call? .inventory-contract get-item u1)
```

#### Stock Operations
```clarity
;; Add stock
(contract-call? .inventory-contract add-stock u1 u50)

;; Remove stock
(contract-call? .inventory-contract remove-stock u1 u20)

;; Transfer between items
(contract-call? .inventory-contract transfer-stock u1 u2 u15)
```

### Access Control

#### User Authorization
```clarity
;; Authorize new user (owner only)
(contract-call? .inventory-contract authorize-user 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Revoke user access (owner only)
(contract-call? .inventory-contract revoke-user 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Check authorization status
(contract-call? .inventory-contract is-user-authorized 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Inventory Analysis

#### Stock Monitoring
```clarity
;; Check if item is below threshold
(contract-call? .inventory-contract is-below-threshold u1)

;; Get current stock level
(contract-call? .inventory-contract get-stock-level u1)

;; Calculate inventory value
(contract-call? .inventory-contract calculate-inventory-value u1)
```

#### Transaction History
```clarity
;; Get transaction details
(contract-call? .inventory-contract get-transaction u1)
```

### Advanced Operations

#### Batch Updates
```clarity
;; Update multiple thresholds
(contract-call? .inventory-contract batch-update-thresholds 
    (list 
        {item-id: u1, min-threshold: u5}
        {item-id: u2, min-threshold: u8}
    )
)
```

#### Emergency Functions
```clarity
;; Emergency stock adjustment (owner only)
(contract-call? .inventory-contract emergency-stock-adjustment u1 u200)
```

## Data Validation

The contract implements comprehensive validation including:

- **String Length Validation**: Names and descriptions must be within specified limits
- **Positive Values**: Quantities and prices must be positive where required
- **ID Validation**: All referenced IDs must exist in the system
- **Principal Validation**: User principals must be valid blockchain addresses

## Security Features

- **Owner Controls**: Critical functions restricted to contract owner
- **User Authorization**: Granular permission system for regular operations
- **Input Validation**: All inputs validated before processing
- **Transaction Recording**: Complete audit trail maintained
- **Error Handling**: Comprehensive error codes for debugging

## Deployment Notes

1. Ensure sufficient STX tokens for deployment gas costs
2. Consider initial supplier setup before item creation
3. Plan user authorization strategy for operational needs
4. Monitor contract storage usage for large inventories

## Integration Examples

### Frontend Integration
The contract is designed for easy frontend integration with clear function signatures and comprehensive error handling. All read-only functions can be called without transaction fees.

### Backend Integration
Transaction history and inventory data can be efficiently queried for reporting and analytics purposes using the provided read-only functions.

## Limitations

- Maximum string lengths enforced for names and descriptions
- List operations limited to 10 items per batch
- No built-in multi-signature functionality
- Storage costs scale with inventory size