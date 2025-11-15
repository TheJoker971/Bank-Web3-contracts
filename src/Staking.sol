// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        uint256 reward;
    }

    IERC20 public euro;
    uint256 public interestRate;
    string public name;

    mapping(address user => Deposit) private deposits;

    constructor(IERC20 _token, string memory _name, uint256 _interestRate) Ownable(msg.sender) {
        euro = _token;
        name = _name;
        interestRate = _interestRate;
    }

    function deposit(address _from, uint256 amount) external onlyOwner returns (bool) {
        if (deposits[_from].amount > 0) {
            deposits[_from].amount += amount;
            deposits[_from].reward += calculeReward(_from);
            deposits[_from].timestamp = block.timestamp;
        } else {
            deposits[_from].amount = amount;
            deposits[_from].timestamp = block.timestamp;
        }
        return true;
    }

    function balance() external view returns (uint256) {
        return euro.balanceOf(address(this));
    }

    function withdrawAll(address to) external onlyOwner returns (bool) {
        uint256 amount = deposits[to].amount;
        uint256 reward = calculeReward(to);
        delete deposits[to];
        uint256 totalAmount = amount + reward;
        return euro.transfer(to, totalAmount);
    }

    function withdrawReward(address to) external onlyOwner returns (bool) {
        uint256 reward = calculeReward(to) + deposits[to].reward;
        deposits[to].timestamp = block.timestamp;
        deposits[to].reward = 0;
        return euro.transfer(to, reward);
    }

    function changeInterestRate(uint256 newRate) external onlyOwner {
        interestRate = newRate;
    }

    function calculeReward(address to) internal view returns (uint256) {
        Deposit memory userDeposit = deposits[to];
        if (userDeposit.amount == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - userDeposit.timestamp;
        uint256 reward = (userDeposit.amount * interestRate * stakingDuration) / (100 * 365 days) / 1 ether;
        return reward;
    }

    function showTotalReward(address _to) external view onlyOwner returns(uint256) {
        return calculeReward(_to);
    }

    receive() external payable {
        // Accept ETH deposits
        return;
    }

    fallback() external payable {
        // Accept ETH deposits
        return;
    }
}
