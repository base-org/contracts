// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { FeeVault } from "@eth-optimism-bedrock/src/universal/FeeVault.sol";

contract FeeVaultRevert {
    address internal immutable _RECIPIENT;
    
    constructor(address _recipient) {
        _RECIPIENT = _recipient;
    }

    function RECIPIENT() external view returns(address) {
        return _RECIPIENT;
    }
    
    function WITHDRAWAL_NETWORK() external pure returns(FeeVault.WithdrawalNetwork) {
        return FeeVault.WithdrawalNetwork.L2;
    }

    function MIN_WITHDRAWAL_AMOUNT() external pure returns(uint256) {
        revert("revert message");
    }
}
