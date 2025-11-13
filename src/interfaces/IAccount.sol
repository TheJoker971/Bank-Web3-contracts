// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAccount {
    function transfer(address to, uint256 amount) external returns (bool);
    function balance() external view returns (uint256);
}
