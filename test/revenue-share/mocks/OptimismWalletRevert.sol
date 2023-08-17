// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract OptimismWalletRevert {
    receive() external payable {
        revert();
    }
}
