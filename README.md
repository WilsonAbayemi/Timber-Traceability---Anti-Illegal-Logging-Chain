A blockchain-based supply chain tracker for timber and wood products built on the Stacks blockchain using Clarity smart contracts.

## 🔴 Problem

- Timber is often sourced from protected areas and illegal logging goes unchecked
- Buyers can't verify the source of wood products
- No transparent supply chain tracking for forest products

## ✅ Solution

A decentralized system that provides end-to-end traceability for timber products using NFT technology and DAO governance.

## ⚙️ Key Features

🏷️ **NFT Timber Tokens**: Every harvested log receives an NFT tied to GPS coordinates and harvesting license

📍 **GPS Tracking**: Precise location data for timber origin verification

🔄 **Processing Steps**: Each manufacturing step updates the NFT metadata

📱 **QR Code Verification**: Buyers can scan product QR codes to verify timber origin

🗳️ **DAO Governance**: Community-driven blacklisting of suspicious harvesters

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Node.js and npm

### Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 📖 Contract Functions

### 🌳 Harvesting Functions

#### `harvest-timber`
Creates a new timber NFT with GPS coordinates and license information.
```clarity
(harvest-timber gps-lat gps-lon harvest-license species)
```

### 🏭 Processing Functions

#### `add-processing-step`
Adds a manufacturing step to the timber's processing history.
```clarity
(add-processing-step token-id step-description)
```

#### `finalize-product`
Marks timber as a final product ready for sale.
```clarity
(finalize-product token-id)
```

### 🔍 Verification Functions

#### `verify-timber-origin`
Returns complete origin and processing information for a timber token.
```clarity
(verify-timber-origin token-id)
```

### 🗳️ Governance Functions

#### `propose-blacklist`
Proposes to blacklist a harvester through DAO voting.
```clarity
(propose-blacklist target-principal)
```

#### `vote-on-proposal`
Vote for or against a blacklist proposal.
```clarity
(vote-on-proposal proposal-id vote-for)
```

#### `execute-blacklist-proposal`
Executes a passed blacklist proposal.
```clarity
(execute-blacklist-proposal proposal-id)
```

## 📊 Usage Examples

### For Harvesters 🪓

1. Register timber harvest:
```clarity
(contract-call? .timber-contract harvest-timber 45123456 -120456789 "LICENSE-2024-001" "Oak")
```

### For Manufacturers 🏭

1. Add processing step:
```clarity
(contract-call? .timber-contract add-processing-step u1 "Cut into planks")
```

2. Finalize product:
```clarity
(contract-call? .timber-contract finalize-product u1)
```

### For Buyers 🛒

1. Verify timber origin:
```clarity
(contract-call? .timber-contract verify-timber-origin u1)
```

### For Governance 🏛️

1. Propose blacklist:
```clarity
(contract-call? .timber-contract propose-blacklist 'SP1ABC...)
```

2. Vote on proposal:
```clarity
(contract-call? .timber-contract vote-on-proposal u1 true)
```

## 🔒 Security Features

- **GPS Validation**: Coordinates must be within valid Earth ranges
- **License Verification**: Harvesting license must be provided
- **Ownership Checks**: Only token owners can modify processing steps
- **DAO Governance**: Community-driven decision making for blacklisting
- **Immutable Records**: All timber history is permanently recorded

## 🌍 Environmental Impact

This system helps combat illegal logging by:
- 📊 Providing transparent supply chain tracking
- 🚫 Enabling community-driven blacklisting of illegal harvesters
- ✅ Allowing consumers to verify sustainable sourcing
- 🔍 Creating an immutable audit trail for regulatory compliance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure contract passes `clarinet check`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, please open an issue in the GitHub repository or contact the development team.

---

Built with 💚 for forest conservation and supply chain transparency

### 🌱 Sustainability Functions

#### `retire-timber`
Allows timber NFT owners to permanently retire their tokens for environmental pledges, transferring them to a burn address and marking as retired.
```clarity
(retire-timber token-id)
```

## 📊 Updated Usage Examples

### For Eco-Conscious Owners 🌍

1. Retire timber NFT for sustainability:
```clarity
(contract-call? .timber-contract retire-timber u1)
```

## 🔒 Updated Security Features

- **Timber Retirement**: Secure, one-way retirement process for environmental commitments
- **Burn Address Protection**: NFTs transferred to dedicated burn address for permanent removal

## 🌍 Enhanced Environmental Impact

This system now supports active environmental stewardship by:
- 🌱 Enabling permanent timber retirement for carbon offset programs
- 🔥 Providing blockchain-verified sustainability pledges
- 📈 Expanding traceability to include retirement status for full lifecycle transparency
