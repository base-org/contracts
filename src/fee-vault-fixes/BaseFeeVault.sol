// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Semver } from "@eth-optimism-bedrock/src/universal/Semver.sol";
import { FeeVault } from "./FeeVault.sol";

/// @custom:proxied
/// @custom:predeploy 0x4200000000000000000000000000000000000011
/// @title BaseFeeVault
/// @notice The BaseFeeVault accumulates the base fee that is paid by transactions.
contract BaseFeeVault is FeeVault, Semver {
    /// @custom:semver 1.2.2
    /// @notice Constructs the BaseFeeVault contract.
    constructor() Semver(1, 2, 2) {}
}
