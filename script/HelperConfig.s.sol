//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script,console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
contract HelperConfig is Script {
    error HelperConfig_InvalidChainID();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }
    address constant BURNER_WALLET =0x8fa4716f3F5C7B772E08C0675375de3EE08e60A8;
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 1155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor(){
        networkConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }
    function getConfig() public  returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }
     function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfig[chainId].account != address(0)) {
            return networkConfig[chainId];
        } else {
            revert HelperConfig_InvalidChainID();
        }
    }


    function getEthSepoliaConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({
            entryPoint:0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account:BURNER_WALLET
        });
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({
            entryPoint:address(0),
            account:BURNER_WALLET
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        // deploy mocks
        console2.log("Deploying mocks...");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        console2.log("Mocks deployed!");

        localNetworkConfig =
            NetworkConfig({entryPoint: address(entryPoint),  account: ANVIL_DEFAULT_ACCOUNT});
        return localNetworkConfig;
    }
}