// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Preinstalls} from "@eth-optimism-bedrock/src/libraries/Preinstalls.sol";

import {DoubleNestedMultisigBuilder} from "../../script/universal/DoubleNestedMultisigBuilder.sol";
import {Simulation} from "../../script/universal/Simulation.sol";
import {IGnosisSafe} from "../../script/universal/IGnosisSafe.sol";
import {Counter} from "./Counter.sol";

contract DoubleNestedMultisigBuilderTest is Test, DoubleNestedMultisigBuilder {
    Vm.Wallet internal wallet1 = vm.createWallet("1");
    Vm.Wallet internal wallet2 = vm.createWallet("2");

    address internal safe1 = address(1001);
    address internal safe2 = address(1002);
    address internal safe3 = address(1003);
    address internal safe4 = address(1004);
    Counter internal counter = new Counter(address(safe4));

    bytes internal dataToSign1 =
    // solhint-disable max-line-length
        hex"1901d4bb33110137810c444c1d9617abe97df097d587ecde64e6fcb38d7f49e1280c32a807b9689901dd0dbb7352e9e6c5265e3f6a68667de4be988f03f6a88511f7";
    bytes internal dataToSign2 =
        hex"190132640243d7aade8c72f3d90d2dbf359e9897feba5fce1453bc8d9e7ba10d171532a807b9689901dd0dbb7352e9e6c5265e3f6a68667de4be988f03f6a88511f7";

    function setUp() public {
        bytes memory safeCode = Preinstalls.getDeployedCode(Preinstalls.Safe_v130, block.chainid);
        vm.etch(safe1, safeCode);
        vm.etch(safe2, safeCode);
        vm.etch(safe3, safeCode);
        vm.etch(safe4, safeCode);
        vm.etch(Preinstalls.MultiCall3, Preinstalls.getDeployedCode(Preinstalls.MultiCall3, block.chainid));

        address[] memory owners1 = new address[](1);
        owners1[0] = wallet1.addr;
        IGnosisSafe(safe1).setup(owners1, 1, address(0), "", address(0), address(0), 0, address(0));

        address[] memory owners2 = new address[](1);
        owners2[0] = wallet2.addr;
        IGnosisSafe(safe2).setup(owners2, 1, address(0), "", address(0), address(0), 0, address(0));

        address[] memory owners3 = new address[](2);
        owners3[0] = safe1;
        owners3[1] = safe2;
        IGnosisSafe(safe3).setup(owners3, 2, address(0), "", address(0), address(0), 0, address(0));

        address[] memory owners4 = new address[](1);
        owners4[0] = safe3;
        IGnosisSafe(safe4).setup(owners4, 1, address(0), "", address(0), address(0), 0, address(0));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        // Check that the counter has been incremented
        uint256 counterValue = counter.count();
        require(counterValue == 1, "Counter value is not 1");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: address(counter),
            allowFailure: false,
            callData: abi.encodeCall(Counter.increment, ())
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return safe4;
    }

    function test_sign_double_nested_safe1() external {
        vm.recordLogs();
        sign(safe1, safe3);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(keccak256(logs[logs.length - 1].data), keccak256(abi.encode(dataToSign1)));
    }

    function test_sign_double_nested_safe2() external {
        vm.recordLogs();
        sign(safe2, safe3);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(keccak256(logs[logs.length - 1].data), keccak256(abi.encode(dataToSign2)));
    }

    function test_approveInit_double_nested_safe1() external {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet1, keccak256(dataToSign1));
        approveOnBehalfOfSignerSafe(safe1, safe3, abi.encodePacked(r, s, v));
    }

    function test_approveInit_double_nested_safe2() external {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet2, keccak256(dataToSign2));
        approveOnBehalfOfSignerSafe(safe2, safe3, abi.encodePacked(r, s, v));
    }

    function test_approveInit_double_nested_notOwner() external {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet1, keccak256(dataToSign1));
        bytes memory data = abi.encodeCall(this.approveOnBehalfOfSignerSafe, (safe2, safe3, abi.encodePacked(r, s, v)));
        (bool success, bytes memory result) = address(this).call(data);
        assertFalse(success);
        assertEq(result, abi.encodeWithSignature("Error(string)", "not enough signatures"));
    }

    function test_runInit_double_nested() external {
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(wallet1, keccak256(dataToSign1));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(wallet2, keccak256(dataToSign2));
        approveOnBehalfOfSignerSafe(safe1, safe3, abi.encodePacked(r1, s1, v1));
        approveOnBehalfOfSignerSafe(safe2, safe3, abi.encodePacked(r2, s2, v2));
        approveOnBehalfOfIntermediateSafe(safe3);
    }

    function test_runInit_double_nested_notApproved() external {
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(wallet1, keccak256(dataToSign1));
        approveOnBehalfOfSignerSafe(safe1, safe3, abi.encodePacked(r1, s1, v1));
        bytes memory data = abi.encodeCall(this.approveOnBehalfOfIntermediateSafe, (safe3));
        (bool success, bytes memory result) = address(this).call(data);
        assertFalse(success);
        assertEq(result, abi.encodeWithSignature("Error(string)", "not enough signatures"));
    }

    function test_run_double_nested() external {
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(wallet1, keccak256(dataToSign1));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(wallet2, keccak256(dataToSign2));
        approveOnBehalfOfSignerSafe(safe1, safe3, abi.encodePacked(r1, s1, v1));
        approveOnBehalfOfSignerSafe(safe2, safe3, abi.encodePacked(r2, s2, v2));
        approveOnBehalfOfIntermediateSafe(safe3);

        run();
    }
}
