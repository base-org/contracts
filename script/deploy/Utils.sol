// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract Utils is Script {
    using stdJson for string;

    struct DeployBedrockConfig {
        address baseFeeVaultRecipient;
        address batchSenderAddress;
        address controller;
        address deployerAddress;
        address finalSystemOwner;
        uint256 finalizationPeriodSeconds;
        uint256 gasPriceOracleOverhead;
        uint256 gasPriceOracleScalar;
        address l1FeeVaultRecipient;
        uint256 l2BlockTime;
        uint256 l2ChainId;
        uint64 l2GenesisBlockGasLimit;
        address l2OutputOracleChallenger;
        address l2OutputOracleProposer;
        uint256 l2OutputOracleStartingBlockNumber;
        uint256 l2OutputOracleSubmissionInterval;
        address p2pSequencerAddress;
        address proxyAdminOwner;
        address sequencerFeeVaultRecipient;
    }

    struct AddressesConfig {
        address AddressManager;
        uint BlockNumber;
        uint BlockTimestamp;
        address L1CrossDomainMessengerProxy;
        address L1ERC721BridgeProxy;
        address L1StandardBridgeProxy;
        address L2OutputOracleProxy;
        address OptimismMintableERC20FactoryProxy;
        address OptimismPortalProxy;
        address ProxyAdmin;
        address SystemConfigProxy;
        address SystemDictatorProxy;
    }

    function getDeployBedrockConfig() external view returns(DeployBedrockConfig memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/inputs/foundry-config.json");
        string memory json = vm.readFile(path);
        bytes memory deployBedrockConfigRaw = json.parseRaw(".deployConfig");
        return abi.decode(deployBedrockConfigRaw, (DeployBedrockConfig));
    }

    function readAddressesFile() external view returns (AddressesConfig memory) {
        string memory root = vm.projectRoot();
        string memory addressPath = string.concat(root, "/inputs/addresses.json");
        string memory addressJson = vm.readFile(addressPath);
        bytes memory addressRaw = vm.parseJson(addressJson);
        return abi.decode(addressRaw, (AddressesConfig));
    }

    function writeAddressesFile(AddressesConfig memory cfg) external {
        string memory json= "";

        // Proxy contract addresses
        vm.serializeAddress(json, "ProxyAdmin", cfg.ProxyAdmin);
        vm.serializeAddress(json, "AddressManager", cfg.AddressManager);
        vm.serializeAddress(json, "L1StandardBridgeProxy", cfg.L1StandardBridgeProxy);
        vm.serializeAddress(json, "L2OutputOracleProxy", cfg.L2OutputOracleProxy);
        vm.serializeAddress(json, "L1CrossDomainMessengerProxy", cfg.L1CrossDomainMessengerProxy);
        vm.serializeAddress(json, "OptimismPortalProxy", cfg.OptimismPortalProxy);
        vm.serializeAddress(json, "OptimismMintableERC20FactoryProxy", cfg.OptimismMintableERC20FactoryProxy);
        vm.serializeAddress(json, "L1ERC721BridgeProxy", cfg.L1ERC721BridgeProxy);
        vm.serializeAddress(json, "SystemConfigProxy", cfg.SystemConfigProxy);
        vm.serializeAddress(json, "SystemDictatorProxy", cfg.SystemDictatorProxy);

        vm.serializeUint(json, "BlockNumber", cfg.BlockNumber);
        string memory finalJson = vm.serializeUint(json, "BlockTimestamp", cfg.BlockTimestamp);

        finalJson.write(string.concat("unsorted.json"));
    }
}