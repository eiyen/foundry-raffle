// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev 合约的实现逻辑如下：
 *
 * 1. 参与抽奖：设置一个参与抽奖的函数，当用户通过该函数转账超过门票的金额后，即可参与抽奖。
 * 2. 开奖条件：设置开奖条件，只有当处于开奖状态、且经过了一段时间、且有玩家参与、且合约有余额的情况下，才能够开奖。
 * 3. 进行抽奖：在达成开奖条件的情况下，通过 Chainlink VRF 获得随机数。
 * 4. 奖金转账：让随机数和参与玩家的数量取模，余数即为中奖者的序号，然后再取得该玩家的地址，最后进行转账。
 */
contract Raffle {
    /**
     * Section 1: Enviroment Setup
     */

    /* Type Deceleration */
    enum RaffleStates {
        OPEN,
        CALCULATING
    }

    /* State Variable Deceleration */
    RaffleStates private s_raffleState;
    uint256 private s_ticketPrice;
    address[] private s_ticketHolders;

    /* Event Deceleration */
    event TicketPurchased(
        uint256 indexed ticketHolderIndex,
        address indexed ticketHolder
    );

    /* Error Function Deceleration */
    error Raffle__InsufficientFundsToPurchaseTicket(
        uint256 sentAmount,
        uint256 requiredAmount
    );
    error Raffle__RaffleNotOpen(RaffleStates);

    /* Constructor Function Deceleration */
    constructor(uint256 ticketPrice) {
        s_ticketPrice = ticketPrice;
        s_raffleState = RaffleStates.OPEN;
    }

    /**
     * Section 2: Core Logic Functions
     */

    /* buyTicket function */
    function buyTicket() external payable {
        if (s_raffleState != RaffleStates.OPEN) {
            revert Raffle__RaffleNotOpen(s_raffleState);
        }
        if (msg.value < s_ticketPrice) {
            revert Raffle__InsufficientFundsToPurchaseTicket(
                msg.value,
                s_ticketPrice
            );

        }
        s_ticketHolders.push(msg.sender);
        emit TicketPurchased(s_ticketHolders.length - 1, msg.sender);
    }

    /**
     * Section 3: Getter Functions
     */

    function getRaffleState() external view returns (RaffleStates) {
        return s_raffleState;
    }

    function getTicketHolder(uint256 index) external view returns (address) {
        return s_ticketHolders[index];
    }
}
