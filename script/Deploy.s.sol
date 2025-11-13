// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console} from "forge-std/Script.sol";
import {Bank} from "../src/Bank.sol";
import {IAccount} from "../src/interfaces/IAccount.sol";
import {Euro} from "../src/Euro.sol";
import {Share} from "../src/Share.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        Bank bank = new Bank("My Bank");

        console.log("Bank deployed at:", address(bank));

        vm.stopBroadcast();
    }
}
