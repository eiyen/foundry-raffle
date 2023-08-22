// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleScript is Script {
    uint256 constant TICKET_PRICE = 0.1 ether;
    uint256 constant MINIMUM_OPEN_TIME = 1 hours;

    function run() external returns(Raffle) {
        vm.broadcast();
        Raffle raffle = new Raffle(TICKET_PRICE, block.timestamp, MINIMUM_OPEN_TIME);

        return raffle;
    }
}