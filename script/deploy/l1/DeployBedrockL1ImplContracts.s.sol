// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import "@eth-optimism-bedrock/contracts/L1/L1CrossDomainMessenger.sol";
import "@eth-optimism-bedrock/contracts/L1/L1StandardBridge.sol";
import "@eth-optimism-bedrock/contracts/L1/L2OutputOracle.sol";
import "@eth-optimism-bedrock/contracts/L1/OptimismPortal.sol";
import "@eth-optimism-bedrock/contracts/L1/ResourceMetering.sol";
import "@eth-optimism-bedrock/contracts/L1/SystemConfig.sol";
import "@eth-optimism-bedrock/contracts/universal/OptimismMintableERC20Factory.sol";
import "@eth-optimism-bedrock/contracts/L1/L1ERC721Bridge.sol";

import "script/deploy/Utils.sol";

// This script deploys the L1 Contract implementations. This is heavily borrowed from the 
// generic DeployScript, but doesn't deal with deploying Proxies / changing ownership,
contract DeployBedrockL1ImplContracts is Script {
    using stdJson for string;

    Utils utils;
    address deployer;
    Utils.DeployBedrockConfig deployConfig;
    bytes32 batcherHash;

    // Implementations
    L1CrossDomainMessenger l1CrossDomainMessengerImpl;
    L1StandardBridge l1StandardBridgeImpl;
    L2OutputOracle l2OutputOracleImpl;
    OptimismPortal optimismPortalImpl;
    OptimismMintableERC20Factory optimismMintableERC20FactoryImpl;
    L1ERC721Bridge l1ERC721BridgeImpl;
    SystemConfig systemConfigImpl;

    function run() public {
        utils = new Utils();
        Utils.AddressesConfig memory addressCfg = utils.readAddressesFile();
        deployConfig = utils.getDeployBedrockConfig();
        deployer = deployConfig.deployerAddress;
        batcherHash = bytes32(abi.encode(deployConfig.batchSenderAddress));
    
        // Deploy L1CrossDomainMessengerImpl
        vm.broadcast(deployer);
        l1CrossDomainMessengerImpl = new L1CrossDomainMessenger(OptimismPortal(payable(addressCfg.OptimismPortalProxy)));
        vm.prank(address(0));
        require(address(l1CrossDomainMessengerImpl.PORTAL()) == addressCfg.OptimismPortalProxy, "Deploy: l1CrossDomainMessenger portal proxy is incorrect");

        // Deploy L1StandardBridgeImpl
        vm.broadcast(deployer);
        l1StandardBridgeImpl = new L1StandardBridge(payable(addressCfg.L1CrossDomainMessengerProxy));
        require(address(l1StandardBridgeImpl.MESSENGER()) == addressCfg.L1CrossDomainMessengerProxy, "Deploy: l1StandardBridge l1 cross domain messenger proxy is incorrect");
        require(address(l1StandardBridgeImpl.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE, "Deploy: l1StandardBridge other bridge is incorrect");

        // Deploy L2OutputOracleImpl
        vm.broadcast(deployer);
        l2OutputOracleImpl = new L2OutputOracle(
            deployConfig.l2OutputOracleSubmissionInterval,
            deployConfig.l2BlockTime,
            0,
            0,
            deployConfig.l2OutputOracleProposer,
            deployConfig.l2OutputOracleChallenger,
            deployConfig.finalizationPeriodSeconds
        );
        require(l2OutputOracleImpl.SUBMISSION_INTERVAL() == deployConfig.l2OutputOracleSubmissionInterval, "Deploy: l2OutputOracle submissionInterval is incorrect");
        require(l2OutputOracleImpl.L2_BLOCK_TIME() == deployConfig.l2BlockTime, "Deploy: l2OutputOracle l2BlockTime is incorrect");
        require(l2OutputOracleImpl.startingBlockNumber() == 0, "Deploy: l2OutputOracle startingBlockNumber is incorrect");
        require(l2OutputOracleImpl.startingTimestamp() == 0, "Deploy: l2OutputOracle startingTimestamp is incorrect");
        require(l2OutputOracleImpl.PROPOSER() == deployConfig.l2OutputOracleProposer, "Deploy: l2OutputOracle proposer is incorrect");
        require(l2OutputOracleImpl.CHALLENGER() == deployConfig.l2OutputOracleChallenger, "Deploy: l2OutputOracle challenger is incorrect");
        require(l2OutputOracleImpl.FINALIZATION_PERIOD_SECONDS() == deployConfig.finalizationPeriodSeconds, "Deploy: l2OutputOracle finalizationPeriodSeconds is incorrect");

        // Deploy OptimismPortalImpl
        vm.broadcast(deployer);
        optimismPortalImpl = new OptimismPortal(
            L2OutputOracle(addressCfg.L2OutputOracleProxy),
            deployConfig.l2OutputOracleChallenger,
            true,
            SystemConfig(addressCfg.SystemConfigProxy)
        );
        require(address(optimismPortalImpl.L2_ORACLE()) == addressCfg.L2OutputOracleProxy, "Deploy: optimismPortal l2OutputOracle proxy is incorrect");
        require(optimismPortalImpl.GUARDIAN() == deployConfig.l2OutputOracleChallenger, "Deploy: optimismPortal GUARDIAN is incorrect");
        require(optimismPortalImpl.paused() == true, "Deploy: optimismPortal pause state is incorrect");
        require(address(optimismPortalImpl.SYSTEM_CONFIG()) == addressCfg.SystemConfigProxy, "Deploy: optimismPortal SystemConfig is incorrect");
        
        // Deploy OptimismMintableERC20FactoryImpl
        vm.broadcast(deployer);
        optimismMintableERC20FactoryImpl = new OptimismMintableERC20Factory(addressCfg.L1StandardBridgeProxy);
        require(optimismMintableERC20FactoryImpl.BRIDGE() == addressCfg.L1StandardBridgeProxy, "Deploy: optimismMintableERC20Factory l1StandardBridgeProxy is incorrect");

        // Deploy L1ERC721BridgeImpl
        vm.broadcast(deployer);
        l1ERC721BridgeImpl = new L1ERC721Bridge(addressCfg.L1CrossDomainMessengerProxy, Predeploys.L2_ERC721_BRIDGE);
        require(address(l1ERC721BridgeImpl.MESSENGER()) == addressCfg.L1CrossDomainMessengerProxy, "Deploy: l1ERC721Bridge l1CrossDomainMessengerProxy is incorrect");
        require(l1ERC721BridgeImpl.OTHER_BRIDGE() == Predeploys.L2_ERC721_BRIDGE, "Deploy: l1ERC721Bridge l2ERC721Briddge is incorrect");

        // Deploy SystemConfigImpl
        ResourceMetering.ResourceConfig memory defaultResourceCfg = Constants.DEFAULT_RESOURCE_CONFIG();
        vm.broadcast(deployer);
        systemConfigImpl = new SystemConfig(
            deployConfig.finalSystemOwner,
            deployConfig.gasPriceOracleOverhead,
            deployConfig.gasPriceOracleScalar,
            batcherHash,
            deployConfig.l2GenesisBlockGasLimit,
            deployConfig.p2pSequencerAddress,
            defaultResourceCfg
        );
        require(address(systemConfigImpl.owner()) == deployConfig.finalSystemOwner, "Deploy: systemConfig finalSystemOwner is incorrect");
        require(systemConfigImpl.overhead() == deployConfig.gasPriceOracleOverhead, "Deploy: systemConfig gasPriceOracleOverhead is incorrect");
        require(systemConfigImpl.scalar() == deployConfig.gasPriceOracleScalar, "Deploy: systemConfig gasPriceOracleScalar is incorrect");
        require(systemConfigImpl.batcherHash() == batcherHash, "Deploy: systemConfig batcherHash is incorrect");
        require(systemConfigImpl.gasLimit() == deployConfig.l2GenesisBlockGasLimit, "Deploy: systemConfig l2GenesisBlockGasLimit is incorrect");
        require(systemConfigImpl.unsafeBlockSigner() == deployConfig.p2pSequencerAddress, "Deploy: systemConfig p2pSequencerAddress is incorrect");
    }
}