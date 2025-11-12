// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {Account} from "../src/Account.sol";
import {Euro} from "../src/Euro.sol";
import {Share} from "../src/Share.sol";

contract BankTest is Test {
    Bank bank;
    Euro euro;
    Share share;

    function setUp() public {
        bank = new Bank("Test Bank");
        euro = bank.euroToken();
        share = new Share("Test Share", "TSH", 1000 ether, 1 ether, address(euro));
    }

    function testCreateAccount() public {
        address accountAddress = bank.createAccount("John", "Doe", 123456);
        assert(accountAddress != address(0));
    }

    function testGetAccount() public {
        address account = bank.createAccount("Jane", "Doe", 654321);
        address accountAddress = bank.getAccount("Jane", "Doe", 654321);
        assert(accountAddress != address(0));
        assertEq(account, accountAddress);
    }

    function testCreateDuplicateAccount() public {
        bank.createAccount("Alice", "Smith", 111111);
        vm.expectRevert(Bank.AccountAlreadyExists.selector);
        bank.createAccount("Alice", "Smith", 111111);
    }

    function testGetNonExistentAccount() public {
        vm.expectRevert(Bank.AccountDoesNotExist.selector);
        bank.getAccount("Bob", "Smith", 222222);
    }

    function testEuroMinting() public {
        address accountAddress = bank.createAccount("Charlie", "Brown", 333333);
        uint256 balance = euro.balanceOf(accountAddress);
        assertEq(balance, 1000 ether);
        assertEq(euro.totalSupply(), 1_000_000_001_000 ether);
        assertEq(bank.getBalanceOfAccount(accountAddress), 1000 ether);
    }

    function testShareCreation() public {
        bank.createShare("My Share", "MSH", 5000 ether, 2 ether);
        Share createdShare = bank.getShare("My Share", "MSH");
        assert(address(createdShare) != address(0));
        assertEq(createdShare.totalSupply(), 0);
    }
    
}