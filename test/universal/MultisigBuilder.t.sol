// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Preinstalls} from "@eth-optimism-bedrock/src/libraries/Preinstalls.sol";
import {MultisigBuilder} from "../../script/universal/MultisigBuilder.sol";
import {Simulation} from "../../script/universal/Simulation.sol";
import {IGnosisSafe} from "../../script/universal/IGnosisSafe.sol";
import {Counter} from "./Counter.sol";

contract MultisigBuilderTest is Test, MultisigBuilder {
    Vm.Wallet internal wallet1 = vm.createWallet("1");
    Vm.Wallet internal wallet2 = vm.createWallet("2");

    address internal safe = address(1001);
    Counter internal counter = new Counter(address(safe));

    bytes internal dataToSign =
        hex"1901d4bb33110137810c444c1d9617abe97df097d587ecde64e6fcb38d7f49e1280c41dcff2c17a271265df60d1612a7387110475b6fc5178add5518196db5dba6bd";

    function setUp() public {
        vm.etch(safe, Preinstalls.getDeployedCode(Preinstalls.Safe_v130, block.chainid));
        vm.etch(Preinstalls.MultiCall3, Preinstalls.getDeployedCode(Preinstalls.MultiCall3, block.chainid));

        address[] memory owners = new address[](2);
        owners[0] = wallet1.addr;
        owners[1] = wallet2.addr;
        IGnosisSafe(safe).setup(owners, 2, address(0), "", address(0), address(0), 0, address(0));
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
        return address(safe);
    }

    function test_sign() external {
        vm.recordLogs();
        sign();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(keccak256(logs[logs.length - 1].data), keccak256(abi.encode(dataToSign)));
    }

    function test_run() external {
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(wallet1, keccak256(dataToSign));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(wallet2, keccak256(dataToSign));
        bytes memory signatures = abi.encodePacked(r1, s1, v1, r2, s2, v2);
        run(signatures);
    }
}
