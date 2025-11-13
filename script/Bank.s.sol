// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";
import {IAccount} from "../src/interfaces/IAccount.sol";
import {Euro} from "../src/Euro.sol";
import {Share} from "../src/Share.sol";

contract BankScript is Script {
    function run() external {
        vm.startBroadcast();

        Bank bank = new Bank("My Bank");

        // Create an account
        address accountAddress = bank.createAccount("John", "Doe", 123456);
        IAccount account = IAccount(accountAddress);

        // Check Euro balance
        Euro euro = bank.euroToken();
        uint256 balance = euro.balanceOf(accountAddress);

        // Create a share
        bank.createShare("My Share", "MSH", 10000 ether, 1 ether);

        vm.stopBroadcast();
    }
}
