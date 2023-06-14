// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import "@eth-optimism-bedrock/contracts/L2/BaseFeeVault.sol";
import "@eth-optimism-bedrock/contracts/L2/GasPriceOracle.sol";
import "@eth-optimism-bedrock/contracts/L2/L1Block.sol";
import "@eth-optimism-bedrock/contracts/L2/L1FeeVault.sol";
import "@eth-optimism-bedrock/contracts/L2/L2CrossDomainMessenger.sol";
import "@eth-optimism-bedrock/contracts/L2/L2ERC721Bridge.sol";
import "@eth-optimism-bedrock/contracts/L2/L2StandardBridge.sol";
import "@eth-optimism-bedrock/contracts/L2/L2ToL1MessagePasser.sol";
import "@eth-optimism-bedrock/contracts/L2/SequencerFeeVault.sol";
import "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC20Factory.sol";
import "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC721Factory.sol";

import "script/deploy/Utils.sol";

// This script deploys the L2 Contract implementations. This is done as part of genesis, 
// so we don't need to do it initially. But as part of an upgrade (such as the post Sherlock
// upgrade), it may be necessary
contract DeployBedrockL2ImplContracts is Script {
    using stdJson for string;

    Utils utils;
    address deployer;
    Utils.DeployBedrockConfig deployConfig;
    Utils.AddressesL2ImplementationsConfig addressL2Cfg;

    // Implementations
    BaseFeeVault baseFeeVaultImpl;
    GasPriceOracle gasPriceOracleImpl;
    L1Block l1BlockImpl;
    L1FeeVault l1FeeVaultImpl;
    L2CrossDomainMessenger l2CrossDomainMessengerImpl;
    L2ERC721Bridge l2ERC721BridgeImpl;
    L2StandardBridge l2StandardBridgeImpl;
    L2ToL1MessagePasser l2ToL1MessagePasserImpl;
    SequencerFeeVault sequencerFeeVaultImpl;
    OptimismMintableERC20Factory optimismMintableERC20FactoryImpl;
    OptimismMintableERC721Factory optimismMintableERC721FactoryImpl;

    function run() public {
        utils = new Utils();
        Utils.AddressesConfig memory addressCfg = utils.readAddressesFile();
        deployConfig = utils.getDeployBedrockConfig();
        deployer = deployConfig.deployerAddress;

        // Deploy BaseFeeVault
        vm.broadcast(deployer);
        baseFeeVaultImpl = new BaseFeeVault(deployConfig.baseFeeVaultRecipient);

        // Deploy GasPriceOracle
        vm.broadcast(deployer);
        gasPriceOracleImpl = new GasPriceOracle();

        // Deploy L1Block
        vm.broadcast(deployer);
        l1BlockImpl = new L1Block();

        // Deploy L1FeeVault
        vm.broadcast(deployer);
        l1FeeVaultImpl = new L1FeeVault(deployConfig.l1FeeVaultRecipient);

        // Deploy L2CrossDomainMessenger
        vm.broadcast(deployer);
        l2CrossDomainMessengerImpl = new L2CrossDomainMessenger(addressCfg.L1CrossDomainMessengerProxy);
        vm.prank(address(0));
        require(address(l2CrossDomainMessengerImpl.OTHER_MESSENGER()) == addressCfg.L1CrossDomainMessengerProxy, "Deploy: l1CrossDomainMessenger proxy is incorrect");

        // Deploy L2ERC721Bridge
        vm.broadcast(deployer);
        l2ERC721BridgeImpl = new L2ERC721Bridge(Predeploys.L2_CROSS_DOMAIN_MESSENGER, addressCfg.L1ERC721BridgeProxy);
        require(address(l2ERC721BridgeImpl.MESSENGER()) == address(Predeploys.L2_CROSS_DOMAIN_MESSENGER), "Deploy: l2ERC721Bridge l2CrossDomainMessengerProxy is incorrect");
        require(l2ERC721BridgeImpl.OTHER_BRIDGE() == addressCfg.L1ERC721BridgeProxy, "Deploy: l2ERC721Bridge l1ERC721Briddge is incorrect");

        // Deploy L2StandardBridge
        vm.broadcast(deployer);
        l2StandardBridgeImpl = new L2StandardBridge(payable(addressCfg.L1StandardBridgeProxy));
        require(address(l2StandardBridgeImpl.MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "Deploy: l2StandardBridge l2 cross domain messenger proxy is incorrect");
        require(address(l2StandardBridgeImpl.OTHER_BRIDGE()) == addressCfg.L1StandardBridgeProxy, "Deploy: l2StandardBridge other bridge is incorrect");

        // Deploy L2ToL1MessagePasser
        vm.broadcast(deployer);
        l2ToL1MessagePasserImpl = new L2ToL1MessagePasser();

        // Deploy SequencerFeeVault
        vm.broadcast(deployer);
        sequencerFeeVaultImpl = new SequencerFeeVault(deployConfig.sequencerFeeVaultRecipient);

        // Deploy OptimismMintableERC20Factory
        vm.broadcast(deployer);
        optimismMintableERC20FactoryImpl = new OptimismMintableERC20Factory(Predeploys.L2_STANDARD_BRIDGE);
        require(address(optimismMintableERC20FactoryImpl.BRIDGE()) == address(Predeploys.L2_STANDARD_BRIDGE), "Deploy: optimismMintableERC20Factory l2StandardBridgeProxy is incorrect");

        // Deploy OptimismMintableERC721Factory
        vm.broadcast(deployer);
        optimismMintableERC721FactoryImpl = new OptimismMintableERC721Factory(Predeploys.L2_ERC721_BRIDGE, deployConfig.l2ChainId);
        require(address(optimismMintableERC721FactoryImpl.BRIDGE()) == address(Predeploys.L2_ERC721_BRIDGE), "Deploy: optimismMintableERC721Factory l2ERC721BridgeProxy is incorrect");
        require(optimismMintableERC721FactoryImpl.REMOTE_CHAIN_ID() == deployConfig.l2ChainId, "Deploy: optimismMintableERC721Factory chain ID is incorrect");

        // Publish L2 implementation contract addresses
        addressL2Cfg.BaseFeeVault = address(baseFeeVaultImpl);
        addressL2Cfg.GasPriceOracle = address(gasPriceOracleImpl);
        addressL2Cfg.L1Block = address(l1BlockImpl);
        addressL2Cfg.L1FeeVault = address(l1FeeVaultImpl);
        addressL2Cfg.L2CrossDomainMessenger = address(l2CrossDomainMessengerImpl);
        addressL2Cfg.L2ERC721Bridge = address(l2ERC721BridgeImpl);
        addressL2Cfg.L2StandardBridge = address(l2StandardBridgeImpl);
        addressL2Cfg.L2ToL1MessagePasser = address(l2ToL1MessagePasserImpl);
        addressL2Cfg.SequencerFeeVault = address(sequencerFeeVaultImpl);
        addressL2Cfg.OptimismMintableERC20Factory = address(optimismMintableERC20FactoryImpl);
        addressL2Cfg.OptimismMintableERC721Factory = address(optimismMintableERC721FactoryImpl);

        utils.writeImplAddressesL2File(addressL2Cfg);
    }
}
