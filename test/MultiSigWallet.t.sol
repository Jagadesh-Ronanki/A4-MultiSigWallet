// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";


contract TestContract {
    uint public i;

    function callMe(uint j) public {
        i += j;
    }

    function getData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", 1);
    }
}

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWalletContract;
    TestContract public testContract;

    address[] public owners;
    uint256 public requiredConfirmations;

    modifier submitTx() {
        address to = makeAddr("to");
        uint256 value = 1 ether;
        bytes memory data = testContract.getData();

        vm.prank(owners[0]);
        multiSigWalletContract.submitTransaction(
            to,
            value,
            data
        );
        _;
    }

    modifier confirmTx() {
        for(uint256 i; i<owners.length; i++) {
            vm.prank(owners[i]);
            multiSigWalletContract.confirmTransaction(0);
        }
        _;
    }

    modifier executeTx() {
        vm.prank(owners[0]);
        multiSigWalletContract.executeTransaction(0);
        _;
    }

    function setUp() public {
        owners = [
            makeAddr("owner1"),
            makeAddr("owner2"),
            makeAddr("owner3"),
            makeAddr("owner4"),
            makeAddr("owner5")
        ];

        uint256 len = owners.length;
        for (uint i; i<len; i++) {
            vm.deal(owners[i], 10 ether);
        }

        requiredConfirmations = 5;

        multiSigWalletContract = new MultiSigWallet(owners, requiredConfirmations);
        testContract = new TestContract();

        // fund contract
        vm.deal(address(multiSigWalletContract), 100 ether);
    }

    function test_owners() public {
        assertEq(multiSigWalletContract.getOwners(), owners);
    }

    function test_requiredConfirmations() public {
        assertEq(multiSigWalletContract.requiredConfirmations(), requiredConfirmations);
    }

    function test_submitTx() public {
        address to = makeAddr("to");
        uint256 value = 1 ether;
        bytes memory data = testContract.getData();

        vm.prank(owners[0]);
        multiSigWalletContract.submitTransaction(
            to,
            value,
            data
        );

        (address _to, uint256 _value, bytes memory _data, bool _executed, uint _numConfirmations) = multiSigWalletContract.getTransaction(0);

        assertEq(_to, to);
        assertEq(_value, 1 ether);
        assertEq(_data, data);
        assertEq(_executed, false);
        assertEq(_numConfirmations, 0);
    }

    function testFail_userSubmitTx() public {
        address to = makeAddr("to");
        uint256 value = 1 ether;
        bytes memory data = testContract.getData();

        address sender = makeAddr("user");
        vm.deal(sender, 10 ether);
        vm.prank(sender);
        multiSigWalletContract.submitTransaction(
            to,
            value,
            data
        );
    }

    function test_confirmTx() public submitTx {
        vm.prank(owners[0]);
        multiSigWalletContract.confirmTransaction(0);

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 1);
    }

    function testFail_userConfirmTx() public submitTx {
        vm.prank(makeAddr("user"));
        multiSigWalletContract.confirmTransaction(0); // <- reverts

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 1);
    }

    function testFail_confirmNonExistTx() public {
        vm.prank(owners[0]);
        multiSigWalletContract.confirmTransaction(0); // <- reverts

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 1);
    }

    function testFail_confirmTxOnExecutedTx() public submitTx confirmTx executeTx {
        vm.prank(owners[0]);
        multiSigWalletContract.confirmTransaction(0); // <- reverts

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 6);
    }

    function test_revokeConfirmation() public submitTx confirmTx {
        vm.prank(owners[0]);
        multiSigWalletContract.revokeConfirmation(0);

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 4);
    }

    function testFail_revokeConfirmationByNotConfirmed() public submitTx confirmTx {
        // remove confirmation
        vm.prank(owners[0]);
        multiSigWalletContract.revokeConfirmation(0);

        // this should fail
        vm.prank(owners[0]);
        multiSigWalletContract.revokeConfirmation(0); // <- revert
    }

    function testFail_revokeConfirmationNonExistTx() public {
        vm.prank(owners[0]);
        multiSigWalletContract.revokeConfirmation(0); // <- revert

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 4);
    }

    function testFail_revokeConfirmationOnExecutedTx() public submitTx confirmTx executeTx {
        vm.prank(owners[0]);
        multiSigWalletContract.revokeConfirmation(0); // <- revert

        (, , , , uint _numConfirmations) = multiSigWalletContract.getTransaction(0);
        assertEq(_numConfirmations, 4);
    }

    function test_getTxCount() public submitTx {
        assertEq(multiSigWalletContract.getTransactionCount(), 1);
    }
}