// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultiSigWallet is Script {

    address[] public owners;
    uint256 public requiredConfirmations;

    function run() external returns(MultiSigWallet, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        owners = [
             makeAddr("owner1"),
             makeAddr("owner2"),
             makeAddr("owner3"),
             makeAddr("owner4"),
             makeAddr("owner5")
        ];

        requiredConfirmations = 4;

        vm.startBroadcast(deployerKey);
        MultiSigWallet multiSigWalletContract = new MultiSigWallet(owners, requiredConfirmations);
        vm.stopBroadcast();

        return (multiSigWalletContract, helperConfig);
    }
}