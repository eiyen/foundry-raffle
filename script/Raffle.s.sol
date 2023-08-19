// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleScript is Script {
    function run() external returns(Raffle) {

        vm.broadcast();
        Raffle raffle = new Raffle(0.01 ether);

        return raffle;
    }
}