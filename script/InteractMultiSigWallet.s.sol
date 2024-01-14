// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TestContract} from "../test/MultiSigWallet.t.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {DeployMultiSigWallet} from "./DeployMultiSigWallet.s.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract InteractMultiSigWallet is Script {
    MultiSigWallet multiSigWalletContract;
    HelperConfig helperConfig;

    function run() public {
        DeployMultiSigWallet deploy = new DeployMultiSigWallet();
        (multiSigWalletContract, helperConfig) = deploy.run();
        fundContract();
        uint256 transactionCnt = submitTx();
        confirmTx(transactionCnt);
        revokeConfirmation(transactionCnt,2);
        executeTx(transactionCnt, 0);
    }

    function fundContract() public {
        address funder = makeAddr("funder");
        vm.deal(funder, 100 ether);
        vm.startBroadcast(funder);
        (bool sent, ) = address(multiSigWalletContract).call{value:100 ether}("");
        require(sent, "funding failed");
        vm.stopBroadcast();

        console.log("1. MultiSigWallet funded with:", address(multiSigWalletContract).balance / 1e18, "ether");
    }

    function submitTx() public returns(uint256) {
        (,address testContract,) = helperConfig.activeNetworkConfig();

        address to = makeAddr("to");
        uint256 value = 1 ether;
        bytes memory data = TestContract(testContract).getData();

        vm.startBroadcast(multiSigWalletContract.owners(0));
        multiSigWalletContract.submitTransaction(
            to,
            value,
            data
        );
        vm.stopBroadcast();

        uint256 _tx = multiSigWalletContract.getTransactionCount() - 1;
        (address _to, uint256 _value, bytes memory _data, bool _executed, uint _numConfirmations) = multiSigWalletContract.getTransaction(_tx);
        console.log("2. Transaction Submitted:");
        console.log("=======================");
        console.log("to:", _to);
        console.log("value:", _value/1e18, " ether");
        console.log("data:", vm.toString(_data));
        console.log("executed:", _executed);
        console.log("confirmaions", _numConfirmations);
        console.log("=======================");

        return _tx;
    }

    function confirmTx(uint256 _tx) public {
        for(uint256 i; i<5; i++) {
            vm.broadcast(multiSigWalletContract.owners(i));
            multiSigWalletContract.confirmTransaction(0);
        }

        (,,,,uint numConfirmations) = multiSigWalletContract.getTransaction(_tx);
        console.log("3. Transaction confirmations: ", numConfirmations);
    }

    function revokeConfirmation(uint256 _tx, uint256 _ownerId) public {
        vm.broadcast(multiSigWalletContract.owners(_ownerId));
        multiSigWalletContract.revokeConfirmation(0);

        console.log("4. Owner", _ownerId, "revoked confirmation");
        (,,,,uint numConfirmations) = multiSigWalletContract.getTransaction(_tx);
        console.log("5. Transaction confirmations: ", numConfirmations);
    }

    function executeTx(uint256 _tx, uint256 _ownerId) public {
        vm.broadcast(multiSigWalletContract.owners(_ownerId));
        multiSigWalletContract.executeTransaction(_tx);

        (address to, uint256 value, bytes memory data, bool executed, uint numConfirmations) = multiSigWalletContract.getTransaction(_tx);
        console.log("6. Transaction Submitted:");
        console.log("=======================");
        console.log("to:", to);
        console.log("value:", value/1e18, " ether");
        console.log("data:", vm.toString(data));
        console.log("executed:", executed);
        console.log("confirmaions", numConfirmations);
        console.log("=======================");

        console.log("7. MultiSigWallet funds:", address(multiSigWalletContract).balance / 1e18, "ether");
    }
}