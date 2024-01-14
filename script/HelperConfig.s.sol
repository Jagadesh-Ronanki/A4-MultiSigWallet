// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TestContract} from "../test/MultiSigWallet.t.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint32 callbackGasLimit;
        address testContract;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getMainnetEthConfig()
    public
    view
    returns (NetworkConfig memory mainnetNetworkConfig)
    {
        mainnetNetworkConfig = NetworkConfig({
            callbackGasLimit: 500000, // 500,000 gas
            testContract: address(0), // TODO deploy and modify
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getSepoliaEthConfig()
    public
    view
    returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            callbackGasLimit: 500000, // 500,000 gas
            testContract: address(0), // TODO deploy and modify
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig()
    public
    returns (NetworkConfig memory anvilNetworkConfig)
    {

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        TestContract testContract = new TestContract();
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            callbackGasLimit: 500000, // 500,000 gas
            testContract: address(testContract),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}