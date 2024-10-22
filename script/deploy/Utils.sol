// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
        uint256 l1ChainId;
        address l1FeeVaultRecipient;
        uint256 l2BlockTime;
        uint256 l2ChainId;
        uint64 l2GenesisBlockGasLimit;
        address l2OutputOracleChallenger;
        address l2OutputOracleProposer;
        uint256 l2OutputOracleStartingBlockNumber;
        uint256 l2OutputOracleStartingTimestamp;
        uint256 l2OutputOracleSubmissionInterval;
        address p2pSequencerAddress;
        address portalGuardian;
        address proxyAdminOwner;
        address sequencerFeeVaultRecipient;
    }

    struct AddressesConfig {
        address AddressManager;
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

    struct AddressesL2ImplementationsConfig {
        address BaseFeeVault;
        address GasPriceOracle;
        address L1Block;
        address L1FeeVault;
        address L2CrossDomainMessenger;
        address L2ERC721Bridge;
        address L2StandardBridge;
        address L2ToL1MessagePasser;
        address OptimismMintableERC20Factory;
        address OptimismMintableERC721Factory;
        address SequencerFeeVault;
    }

    function getDeployBedrockConfig() external view returns (DeployBedrockConfig memory) {
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

    function readImplAddressesL2File() external view returns (AddressesL2ImplementationsConfig memory) {
        string memory root = vm.projectRoot();
        string memory addressPath = string.concat(root, "/inputs/addresses-l2.json");
        string memory addressJson = vm.readFile(addressPath);
        bytes memory addressRaw = vm.parseJson(addressJson);
        return abi.decode(addressRaw, (AddressesL2ImplementationsConfig));
    }

    function writeAddressesFile(AddressesConfig memory cfg) external {
        string memory json = "";

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

        string memory finalJson = vm.serializeAddress(json, "SystemDictatorProxy", cfg.SystemDictatorProxy);

        finalJson.write(string.concat("unsorted.json"));
    }

    function writeImplAddressesL2File(AddressesL2ImplementationsConfig memory cfg) external {
        string memory json = "";

        vm.serializeAddress(json, "BaseFeeVault", cfg.BaseFeeVault);
        vm.serializeAddress(json, "GasPriceOracle", cfg.GasPriceOracle);
        vm.serializeAddress(json, "L1Block", cfg.L1Block);
        vm.serializeAddress(json, "L1FeeVault", cfg.L1FeeVault);
        vm.serializeAddress(json, "L2CrossDomainMessenger", cfg.L2CrossDomainMessenger);
        vm.serializeAddress(json, "L2ERC721Bridge", cfg.L2ERC721Bridge);
        vm.serializeAddress(json, "L2StandardBridge", cfg.L2StandardBridge);
        vm.serializeAddress(json, "L2ToL1MessagePasser", cfg.L2ToL1MessagePasser);
        vm.serializeAddress(json, "SequencerFeeVault", cfg.SequencerFeeVault);
        vm.serializeAddress(json, "OptimismMintableERC20Factory", cfg.OptimismMintableERC20Factory);
        string memory finalJson =
            vm.serializeAddress(json, "OptimismMintableERC721Factory", cfg.OptimismMintableERC721Factory);

        finalJson.write(string.concat("unsortedl2Impls.json"));
    }
}
