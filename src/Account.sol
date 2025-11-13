// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Account is Ownable {
    IERC20 public euro;

    constructor(IERC20 _token) Ownable(msg.sender) {
        euro = _token;
    }

    function transfer(address to, uint256 amount) external onlyOwner returns (bool) {
        return euro.transfer(to, amount);
    }

    function balance() external view returns (uint256) {
        return euro.balanceOf(address(this));
    }
}
