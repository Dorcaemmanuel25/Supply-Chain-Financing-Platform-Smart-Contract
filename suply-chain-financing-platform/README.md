# Supply Chain Financing Platform

A decentralized smart contract platform built on Stacks blockchain that facilitates supply chain working capital solutions through invoice financing, connecting suppliers, buyers, and financial institutions.

## Overview

This platform enables suppliers to get early payment for their invoices by connecting them with financial institutions willing to provide financing at competitive rates. Buyers can approve invoices and commit to payments, creating a transparent and efficient supply chain financing ecosystem.

## Key Features

- **Multi-party Registration**: Suppliers, buyers, and financiers can register on the platform
- **Invoice Management**: Create, approve, and track invoices throughout their lifecycle
- **Automated Financing**: Request and approve financing with transparent rate calculations
- **Credit Assessment**: Built-in credit rating and eligibility checks
- **Payment Commitments**: Buyers can guarantee payments to reduce financing risk
- **Transaction Audit Trail**: Complete history of all platform activities
- **Risk Management**: Automated risk scoring and credit limit enforcement

## Architecture

### Core Components

1. **Company Registration System**: Manages all platform participants
2. **Invoice Lifecycle Management**: Tracks invoices from creation to payment
3. **Financing Request Engine**: Handles financing applications and approvals
4. **Payment Processing**: Manages buyer payments and loan repayments
5. **Risk Assessment**: Credit scoring and eligibility verification
6. **Analytics Dashboard**: Platform statistics and performance metrics

### Data Models

#### Companies
- Registration details and verification status
- Credit ratings and limits
- Transaction history and success rates
- Contact information and company type

#### Invoices
- Supplier and buyer information
- Invoice amounts and payment terms
- Approval status and financing eligibility
- Due dates and goods descriptions

#### Financing Requests
- Loan terms and interest rates
- Financing fees and net payments
- Request status and funding dates
- Repayment tracking

#### Financial Institutions
- Institution profiles and licenses
- Funding capacity and rate structures
- Approval status and reputation scores
- Portfolio statistics

## Getting Started

### Prerequisites

- Stacks blockchain wallet
- STX tokens for transaction fees
- Valid business registration documents

### Registration Process

1. **Company Registration**
   ```clarity
   (register-company 
     "Your Company Name"
     "supplier|buyer|financier"
     "REG123456"
     "contact@company.com"
     1000000) ;; Credit limit in micro-STX
   ```

2. **Verification** (Admin Process)
   - Submit required documentation
   - Undergo credit assessment
   - Receive verification and credit rating

3. **Financier Registration** (For Financial Institutions)
   ```clarity
   (register-financier
     "Bank Name"
     "LIC789012"
     10000000  ;; Funding capacity
     50000     ;; Min financing amount
     1000000   ;; Max financing amount
     1200)     ;; Standard rate (12% APR)
   ```

## Usage Guide

### For Suppliers

#### 1. Create Invoice
```clarity
(create-invoice
  'SP2BUYER123...  ;; Buyer principal
  "INV-2024-001"   ;; Invoice number
  100000           ;; Amount in micro-STX
  30               ;; Payment terms (days)
  "Electronics components for Q1 order")
```

#### 2. Request Financing
```clarity
(request-financing
  1                 ;; Invoice ID
  'SP2FINANCIER...  ;; Financier principal
  85000)            ;; Requested amount (85% of invoice)
```

### For Buyers

#### 1. Approve Invoice
```clarity
(approve-invoice 1) ;; Invoice ID
```

#### 2. Process Payment (When Due)
```clarity
(process-payment 1) ;; Financing ID
```

### For Financiers

#### 1. Approve Financing Request
```clarity
(approve-financing 1) ;; Financing ID
```

## Rate Calculation

The platform uses transparent rate calculations:

- **Interest Cost**: Based on annualized rate and financing term
- **Platform Fee**: 2.5% of financed amount (configurable)
- **Net Payment**: Invoice amount minus interest and fees

### Example Calculation
For a $10,000 invoice with 12% APR for 30 days:
- Interest Cost: $98.63
- Platform Fee: $250.00
- Net to Supplier: $9,651.37

## Security Features

### Access Control
- Role-based permissions for different user types
- Owner-only functions for platform administration
- Transaction authorization checks

### Risk Management
- Minimum credit rating requirements (default: 600)
- Maximum financing ratio limits (default: 85%)
- Credit limit enforcement
- Buyer verification requirements

### Audit Trail
- Complete transaction logging
- Immutable blockchain records
- Multi-party transaction tracking
- Platform statistics monitoring

## Platform Statistics

Track key metrics including:
- Total registered companies and financiers
- Invoice volume and financing amounts
- Success rates and default statistics
- Platform fee collection

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | Owner Only | Function restricted to contract owner |
| 101 | Not Found | Requested record doesn't exist |
| 102 | Unauthorized | Caller lacks required permissions |
| 103 | Invalid Amount | Amount is zero or exceeds limits |
| 104 | Invalid Rate | Interest rate outside acceptable range |
| 105 | Not Approved | Supplier or financier not approved |
| 106 | Invoice Expired | Invoice past due date |
| 107 | Financing Exists | Duplicate financing request |
| 108 | Insufficient Credit | Credit limit exceeded |
| 109 | Invalid Terms | Contract terms don't meet requirements |
| 110 | Buyer Not Verified | Buyer verification required |

## Read-Only Functions

Query platform data without transaction fees:

- `get-company-info`: Company registration details
- `get-invoice`: Invoice information and status
- `get-financing-request`: Financing request details
- `get-platform-statistics`: Platform-wide metrics
- `check-financing-eligibility`: Eligibility verification
- `calculate-financing-cost`: Cost estimation

## Admin Functions

Platform administration capabilities:
- Company verification and credit rating assignment
- Platform parameter adjustments (fees, limits)
- Emergency pause functionality
- Financier approval management

## Integration Guide

### API Integration
The platform provides read-only functions for:
- Real-time rate comparison
- Eligibility checking
- Cost calculation
- Status monitoring

### Off-Chain Services
Consider integrating with:
- Credit bureau APIs for enhanced scoring
- Payment processing systems
- Document management platforms
- Notification services

## Best Practices

### For Suppliers
- Maintain good payment history to improve credit ratings
- Provide accurate invoice information
- Monitor financing costs across different providers

### For Buyers
- Approve invoices promptly to reduce supplier costs
- Maintain payment commitments to support ecosystem
- Verify supplier credentials before transactions

### For Financiers
- Set competitive rates to attract business
- Monitor portfolio risk and diversification
- Maintain adequate funding capacity

## Roadmap

- **Phase 1**: Core financing functionality ✅
- **Phase 2**: Advanced risk analytics
- **Phase 3**: Multi-currency support
- **Phase 4**: Insurance integration
- **Phase 5**: AI-powered credit scoring

## Contributing

This is a proprietary smart contract platform. For enterprise integration or partnership opportunities, please contact the development team.

## License

Copyright (c) 2024 Supply Chain Financing Platform. All rights reserved.

## Support

For technical support or integration assistance:
- Documentation: [Platform Docs]
- Developer Support: [Contact Form]
- Enterprise Sales: [Sales Team]

## Disclaimer

This platform facilitates financial transactions between parties. Users are responsible for conducting their own due diligence and risk assessment. The platform does not guarantee loan approvals or payment performance.