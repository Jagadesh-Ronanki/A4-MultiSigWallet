# Multi-Signature Wallet

## Overview

This Solidity contract implements a multi-signature wallet, allowing multiple owners to submit and confirm transactions before their execution. The contract is designed to provide a secure and flexible way for a group of individuals or entities to manage funds collectively. It follows the principles of multi-signature wallets where a predefined number of owners must collectively confirm a transaction before it can be executed.

## Usage
Install foundry, Clone the repository and run

```bash
forge build
```

### Test Script

Run the command to execute the test script

```bash
forge script InteractMultiSigWallet
```

<Details>
<summary>Here is a step-by-step overview of the test script results</summary>

### Step 1: MultiSigWallet funded with: 100 ether
- The script deploys the `MultiSigWallet` contract and funds it with 100 ether.
- Console output: `MultiSigWallet funded with: 100 ether`

### Step 2: Transaction Submitted
- A transaction is submitted to the `MultiSigWallet` contract.
  - Destination address (`to`): 0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87
  - Value: 1 ether
  - Data: 0xe73620c30000000000000000000000000000000000000000000000000000000000000001
  - Executed: false
  - Confirmations: 0
  - Console output:
    ```
    2. Transaction Submitted:
    =======================
    to: 0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87
    value: 1  ether
    data: 0xe73620c30000000000000000000000000000000000000000000000000000000000000001
    executed: false
    confirmaions 0
    =======================
    ```

### Step 3: Transaction Confirmations
- Five owners confirm the submitted transaction.
  - Console output: `3. Transaction confirmations: 5`

### Step 4: Owner 2 revoked confirmation
- Owner 2 revokes their confirmation for the submitted transaction.
  - Console output: `4. Owner 2 revoked confirmation`
  - Confirmations reduced to 4.

### Step 5: Transaction Confirmations
- Console output: `5. Transaction confirmations: 4`

### Step 6: Transaction Submitted (Execution)
- The transaction is executed after receiving the required confirmations.
  - Executed: true
  - Confirmations: 4
  - Console output:
    ```
    6. Transaction Submitted:
    =======================
    to: 0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87
    value: 1  ether
    data: 0xe73620c30000000000000000000000000000000000000000000000000000000000000001
    executed: true
    confirmaions 4
    =======================
    ```

### Step 7: MultiSigWallet funds: 99 ether
- The MultiSigWallet balance is now reduced to 99 ether.
  - Console output: `7. MultiSigWallet funds: 99 ether`

This step-by-step overview reflects the process of funding, submitting a transaction, confirming and revoking confirmations, executing the transaction, and checking the updated balance of the MultiSigWallet during the script execution.
</Details>

### Tests

```bash
forge test
```

## Design Choices

### Multiple Owners
The contract allows for a dynamic list of owners, providing flexibility in the number of participants involved. Owners can be added during deployment, offering scalability to the wallet's management structure.

### Confirmation Mechanism
A confirmation mechanism is implemented to ensure that a transaction can only be executed when a predefined number of owners have confirmed it. This design choice adds an extra layer of security by requiring consensus among the specified number of participants.

### Structured Transaction Storage
Transactions are stored in a structured manner using a `Transaction` struct. This design choice enhances readability and simplifies transaction retrieval, enabling easy access to transaction details.

### Efficient Confirmation Tracking
Confirmation status is tracked efficiently using a mapping structure (`isConfirmed`). This design choice minimizes gas costs associated with tracking confirmations while maintaining an easily verifiable and scalable solution.

## Security Considerations

### Input Validation
The contract checks for various conditions during deployment, such as ensuring a minimum number of owners and valid required confirmation settings. This mitigates potential issues related to zero or duplicate owners and invalid confirmation requirements.

### Access Control
The `onlyOwner` modifier is employed to restrict certain functions to wallet owners only, preventing unauthorized access to critical functionality.

### Transaction Security
The contract ensures that transactions cannot be executed multiple times (`notExecuted` modifier) and that a confirmation cannot be revoked if the owner has not confirmed the transaction (`notConfirmed` modifier). These measures protect against potential double-spending and unauthorized transaction manipulations.

### Reentrancy Protection
The contract uses the Checks-Effects-Interactions pattern to protect against reentrancy attacks. It first updates state variables and then interacts with external contracts, reducing the risk of reentrancy vulnerabilities.