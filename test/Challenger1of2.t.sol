// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import { Test, StdUtils } from "forge-std/Test.sol";

import { L2OutputOracle } from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import { ProxyAdmin } from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import { Proxy } from "@eth-optimism-bedrock/src/universal/Proxy.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Challenger1of2 } from "src/Challenger1of2.sol";

contract Challenger1of2Test is Test {
    address deployer = address(1000);
    address coinbaseWallet = address(1001);
    address optimismWallet = address(1002);
    address randomWallet = address(1003);
    address proposer = address(1004);

    ProxyAdmin proxyAdmin;
    Proxy l2OutputOracleProxy;
    L2OutputOracle l2OutputOracle;
    Challenger1of2 challenger;
   
    bytes DELETE_OUTPUTS_SIGNATURE = abi.encodeWithSignature("deleteL2Outputs(uint256)", 1);
    bytes NONEXISTENT_SIGNATURE = abi.encodeWithSignature("something()");
    bytes ZERO_OUTPUT = new bytes(0);

    uint256 ZERO = 0;
    uint256 NONZERO_INTEGER = 100;

    event ChallengerCallExecuted(
        address indexed _caller,
        bytes _data,
        bytes _result
    );

    event OutputsDeleted(
        address indexed _caller,
        uint256 indexed prevNextOutputIndex,
        uint256 indexed newNextOutputIndex
    );
    
    function setUp() public {
        vm.prank(deployer);
        proxyAdmin = new ProxyAdmin(deployer);
        l2OutputOracleProxy = new Proxy(address(proxyAdmin));

        challenger = new Challenger1of2(
            optimismWallet, coinbaseWallet, address(l2OutputOracleProxy)
        );

        // Initialize L2OutputOracle implementation.
        l2OutputOracle = new L2OutputOracle();

        vm.prank(deployer);
        // Upgrade and initialize L2OutputOracle.
        proxyAdmin.upgradeAndCall(
            payable(l2OutputOracleProxy),
            address(l2OutputOracle),
            abi.encodeCall(
                L2OutputOracle.initialize,
                (
                    NONZERO_INTEGER, // _submissionInterval
                    NONZERO_INTEGER, // _l2BlockTime
                    ZERO, // _startingBlockNumber
                    NONZERO_INTEGER, // _startingTimestamp
                    proposer, // _proposer
                    address(challenger), // _challenger
                    NONZERO_INTEGER // _finalizationPeriodSeconds
                )
            )
        );
    }

    function test_constructor_cbSigner_zeroAddress_fails() external {
        vm.expectRevert("Challenger1of2: otherSigner cannot be zero address");
        new Challenger1of2(optimismWallet, address(0), address(l2OutputOracleProxy));
    }

    function test_constructor_opSigner_zeroAddress_fails() external {
        vm.expectRevert("Challenger1of2: opSigner cannot be zero address");
        new Challenger1of2(address(0), coinbaseWallet, address(l2OutputOracleProxy));
    }

    function test_constructor_l2OO_zeroAddress_fails() external {
        vm.expectRevert("Challenger1of2: l2OutputOracleProxy must be a contract");
        new Challenger1of2(optimismWallet, coinbaseWallet, address(0));
    }

    function test_constructor_success() external {
        Challenger1of2 challenger2 = new Challenger1of2(
            optimismWallet, coinbaseWallet, address(l2OutputOracleProxy)
        );
        assertEq(challenger2.OP_SIGNER(), optimismWallet);
        assertEq(challenger2.OTHER_SIGNER(), coinbaseWallet);
        assertEq(challenger2.L2_OUTPUT_ORACLE_PROXY(), address(l2OutputOracleProxy));
    }

    function test_execute_unauthorized_call_fails() external {
        vm.prank(randomWallet);
        vm.expectRevert("Challenger1of2: must be an approved signer to execute");
        challenger.execute(DELETE_OUTPUTS_SIGNATURE);
    }

    function test_execute_call_fails() external {
        vm.prank(optimismWallet);
        vm.expectRevert("Challenger1of2: failed to execute");
        challenger.execute(NONEXISTENT_SIGNATURE);
    }

    function test_unauthorized_challenger_fails() external {
        // Try to make a call from a second challenger contract (not the official one)
        Challenger1of2 otherChallenger = new Challenger1of2(
            optimismWallet, coinbaseWallet, address(l2OutputOracleProxy)
        );
        vm.prank(optimismWallet);
        vm.expectRevert("L2OutputOracle: only the challenger address can delete outputs");
        otherChallenger.execute(DELETE_OUTPUTS_SIGNATURE);
    }

    function test_execute_opSigner_success() external {
        _proposeOutput();
        _proposeOutput();

        L2OutputOracle oracle = L2OutputOracle(address(l2OutputOracleProxy));
        // Check that the outputs were proposed.
        assertFalse(oracle.latestOutputIndex() == ZERO);

        // We expect the OutputsDeleted event to be emitted
        vm.expectEmit(true, true, true, true, address(challenger));

        // Emit the event we expect to see
        emit ChallengerCallExecuted(optimismWallet, DELETE_OUTPUTS_SIGNATURE, ZERO_OUTPUT);

        // We expect deleteOutputs to be called
        vm.expectCall(
            address(l2OutputOracleProxy),
            abi.encodeWithSignature("deleteL2Outputs(uint256)", 1)
        );

        // Make the call        
        vm.prank(optimismWallet);
        challenger.execute(DELETE_OUTPUTS_SIGNATURE);

        // Check that the outputs were deleted.
        assertEq(oracle.latestOutputIndex(), ZERO);
    }

    function test_execute_cbSigner_success() external {
        _proposeOutput();
        _proposeOutput();

        L2OutputOracle oracle = L2OutputOracle(address(l2OutputOracleProxy));
        // Check that the outputs were proposed.
        assertFalse(oracle.latestOutputIndex() == ZERO);

        // We expect the OutputsDeleted event to be emitted
        vm.expectEmit(true, true, true, true, address(challenger));

        // Emit the event we expect to see
        emit ChallengerCallExecuted(coinbaseWallet, DELETE_OUTPUTS_SIGNATURE, ZERO_OUTPUT);

        // We expect deleteOutputs to be called
        vm.expectCall(
            address(l2OutputOracleProxy),
            abi.encodeWithSignature("deleteL2Outputs(uint256)", 1)
        );

        // Make the call        
        vm.prank(coinbaseWallet);
        challenger.execute(DELETE_OUTPUTS_SIGNATURE);

        // Check that the outputs were deleted.
        assertEq(oracle.latestOutputIndex(), ZERO);
    }

    function _proposeOutput() internal {
        L2OutputOracle oracle = L2OutputOracle(address(l2OutputOracleProxy));
        vm.warp(oracle.computeL2Timestamp(oracle.nextBlockNumber()) + 1);

        vm.startPrank(proposer);
        oracle.proposeL2Output(
            bytes32("something"),
            oracle.nextBlockNumber(),
            blockhash(10),
            10
        );
        vm.stopPrank();
    }
}