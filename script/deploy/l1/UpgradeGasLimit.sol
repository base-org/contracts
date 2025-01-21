// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SetGasLimitBuilder} from "./SetGasLimitBuilder.sol";

contract UpgradeGasLimit is SetGasLimitBuilder {
    function _fromGasLimit() internal view override returns (uint64) {
        return uint64(vm.envUint("OLD_GAS_LIMIT"));
    }

    function _toGasLimit() internal view override returns (uint64) {
        return uint64(vm.envUint("NEW_GAS_LIMIT"));
    }

    function _nonceOffset() internal view override returns (uint64) {
        try vm.envUint("UPGRADE_NONCE_OFFSET") {
            return uint64(vm.envUint("UPGRADE_NONCE_OFFSET"));
        } catch {
            return 0;
        }
    }
}
