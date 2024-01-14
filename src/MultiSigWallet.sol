// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Multi-Signature Wallet
 * @notice This contract allows multiple owners to submit and confirm transactions before execution.
 */
contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredConfirmations;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    /// @dev tracks if owner confirmed the transaction
    mapping(uint256 => mapping(address => bool)) public isConfirmed; // tx.index => owner => bool

    // events
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    // errors
    error Not_Owner();
    error Tx_NotExist();
    error Tx_Executed();
    error Tx_NotExecuted();
    error Tx_Confirmed();
    error Tx_NotConfirmed();
    error Tx_Failed();
    error Zero_Owners();
    error Duplicate_Owner();
    error Invalid_Owner();
    error Invalid_RequiredConfirmations();

    /**
     * @notice Modifier to restrict a function to only the owners of the wallet.
     */
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert Not_Owner();
        _;
    }

    /**
     * @notice Modifier to check if a transaction with a given index exists.
     * @param _txIndex The index of the transaction to check.
     */
    modifier txExists(uint _txIndex) {
        if (_txIndex >= transactions.length) revert Tx_NotExist();
        _;
    }

    /**
     * @notice Modifier to check if a transaction with a given index has not been executed.
     * @param _txIndex The index of the transaction to check.
     */
    modifier notExecuted(uint _txIndex) {
        if (transactions[_txIndex].executed) revert Tx_Executed();
        _;
    }

    /**
     * @notice Modifier to check if a transaction with a given index has not been confirmed by the calling owner.
     * @param _txIndex The index of the transaction to check.
     */
    modifier notConfirmed(uint _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert Tx_Confirmed();
        _;
    }

    /**
     * @notice Contract constructor initializes the owners and required confirmations.
     * @param _owners The initial list of owners for the wallet.
     * @param _requiredConfirmations The number of required owner confirmations for a transaction.
     * @dev   reverts for conditions _owners length is 0 and _requiredConfirmations exceeds _owners length
     */
    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        if (_owners.length < 1) revert Zero_Owners();
        if (_requiredConfirmations < 0 || _requiredConfirmations > _owners.length) revert Invalid_RequiredConfirmations();

        for (uint256 i; i < _owners.length;) {
            address owner = _owners[i];

            if(owner == address(0)) revert Invalid_Owner();
            if (isOwner[owner]) revert Duplicate_Owner();

            isOwner[owner] = true;
            owners.push(owner);

            unchecked {
                i = i+1;
            }
        }

        requiredConfirmations = _requiredConfirmations;
    }

    /**
     * @notice Submits a new transaction to the wallet.
     * @param _to The destination address for the transaction.
     * @param _value The value (in wei) of the transaction.
     * @param _data The data payload of the transaction.
     */
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /**
     * @notice Confirms a transaction by an owner.
     * @param _txIndex The index of the transaction to confirm.
     */
    function confirmTransaction(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Executes a confirmed transaction.
     * @param _txIndex The index of the transaction to execute.
     */
    function executeTransaction(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations < requiredConfirmations) revert Tx_Failed();

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        if(!success) revert Tx_Failed();

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Revokes a confirmation by an owner.
     * @param _txIndex The index of the transaction to revoke confirmation.
     */
    function revokeConfirmation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if(!isConfirmed[_txIndex][msg.sender]) revert Tx_NotConfirmed();

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @notice Gets the list of wallet owners.
     * @return An array containing the addresses of the owners.
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Gets the total number of transactions in the wallet.
     * @return The total number of transactions.
     */
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    /**
     * @notice Gets information about a specific transaction.
     * @param _txIndex The index of the transaction.
     * @return to The destination address of the transaction.
     * @return value The value (in wei) of the transaction.
     * @return data The data payload of the transaction.
     * @return executed Whether the transaction has been executed.
     * @return numConfirmations The number of confirmations for the transaction.
     */
    function getTransaction(uint256 _txIndex) public view returns(address to, uint256 value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /**
     * @notice Fallback function to accept ether deposits.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
