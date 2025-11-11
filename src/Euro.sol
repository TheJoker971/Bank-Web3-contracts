// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20Upgradeable} from "@openzeppelin/contracts/token/ERC20/ERC20Upgradeable.sol";

contract Euro is ERC20Upgradeable {
    constructor(string _name, string _symbol) ERC20Upgradeable(_name,_symbol) {
        _mint(msg.sender, 1000000000000000000000000);
    }
}