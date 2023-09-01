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
     * 第一部分：环境设置
     */

    /* 1. 声明类型 */
    enum RaffleStates {
        OPEN,
        CALCULATING
    }

    /* 2. 声明状态变量 */
    RaffleStates private s_raffleState;
    uint256 private s_ticketPrice;
    uint256 private s_startTime;
    uint256 private s_minimumOpenTime;
    address[] private s_ticketHolders;

    /* 3. 声明事件 */
    event TicketPurchased(
        uint256 indexed ticketHolderIndex,
        address indexed ticketHolder
    );

    /* 4. 声明错误函数 */
    error Raffle__InsufficientFundsToPurchaseTicket(
        uint256 sentAmount,
        uint256 requiredAmount
    );
    error Raffle__RaffleNotOpen(RaffleStates);
    error Raffle__MinimumOpenTimeNotReached(uint256 timeRemaining);
    // error Raffle__MinimumOpenTimeNotReached();

    /* 5. 定义构造函数 */
    constructor(uint256 ticketPrice, uint256 startTime, uint256 minimumOpenTime) {
        s_ticketPrice = ticketPrice;
        s_raffleState = RaffleStates.OPEN;
        s_startTime = startTime;
        s_minimumOpenTime = minimumOpenTime;
    }

    /**
     * 第二部分：核心逻辑函数
     */

    /* 1. buyTicket 购票函数 */
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

    function pickWinner() external payable {
        if (block.timestamp - s_startTime < s_minimumOpenTime) {
            revert Raffle__MinimumOpenTimeNotReached(s_minimumOpenTime - (block.timestamp - s_startTime));
            // revert Raffle__MinimumOpenTimeNotReached();
        }
    }

    /**
     * 第三部分: 获得函数
     */

    function getRaffleState() external view returns (RaffleStates) {
        return s_raffleState;
    }

    function getTicketHolder(uint256 index) external view returns (address) {
        return s_ticketHolders[index];
    }

    function getMinimumOpenTime() external view returns(uint256) {
        return s_minimumOpenTime;
    }

    function getStartTime() external view returns(uint256) {
        return s_startTime;
    }

    /* block.timestamp 测试 */
    function getBlockTimestamp() external view returns(uint256) {
        return block.timestamp;
    }
}
