// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";
import {IAccount} from "../src/interfaces/IAccount.sol";
import {Euro} from "../src/Euro.sol";
import {Share} from "../src/Share.sol";

contract CreateAccountScript is Script {
    function run() external {
        vm.startBroadcast();

        Bank bank = Bank(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        // Create an account
        address accountAddress = bank.createAccount("John", "Doe", 123456);
        console.log("Account created at:", accountAddress);

        assert(bank.getBalanceOfAccount(accountAddress) == 1000 ether);

        vm.stopBroadcast();
    }
}
