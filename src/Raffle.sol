// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @dev 合约的实现逻辑如下：
 *
 * 1. 参与抽奖：设置一个参与抽奖的函数，当用户通过该函数转账超过门票的金额后，即可参与抽奖。
 * 2. 开奖条件：设置开奖条件，只有当处于开奖状态、且经过了一段时间、且有玩家参与、且合约有余额的情况下，才能够开奖。
 * 3. 进行抽奖：在达成开奖条件的情况下，通过 Chainlink VRF 获得随机数。
 * 4. 奖金转账：让随机数和参与玩家的数量取模，余数即为中奖者的序号，然后再取得该玩家的地址，最后进行转账。
 */
contract Raffle is VRFConsumerBaseV2 {
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
    address payable[] private s_ticketHolders;
    address payable s_recentWinner;

    VRFCoordinatorV2Interface private i_vrfCoordinator;
    bytes32 private immutable i_maximumGasPrice;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /* 3. 声明事件 */
    event TicketPurchased(
        uint256 indexed ticketHolderIndex,
        address indexed ticketHolder
    );
    event PickedWinner(address payable indexed winner);

    /* 4. 声明错误函数 */
    error Raffle__InsufficientFundsToPurchaseTicket(
        uint256 sentAmount,
        uint256 requiredAmount
    );
    error Raffle__RaffleNotOpen(RaffleStates);
    error Raffle__RaffleNotCalculating(RaffleStates);
    error Raffle__MinimumOpenTimeNotReached(uint256 timeRemaining);
    error Raffle__TransferFailed(address payable winner);

    // error Raffle__MinimumOpenTimeNotReached();

    /* 5. 定义构造函数 */
    constructor(
        uint256 ticketPrice,
        uint256 startTime,
        uint256 minimumOpenTime,
        address vrfCoordinator,
        bytes32 maximumGasPrice,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        s_ticketPrice = ticketPrice;
        s_raffleState = RaffleStates.OPEN;
        s_startTime = startTime;
        s_minimumOpenTime = minimumOpenTime;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_maximumGasPrice = maximumGasPrice;
        i_subscriptionId = subscriptionId;
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
        s_ticketHolders.push(payable(msg.sender));
        emit TicketPurchased(s_ticketHolders.length - 1, msg.sender);
    }

    function pickWinner() external payable {
        if (block.timestamp - s_startTime < s_minimumOpenTime) {
            revert Raffle__MinimumOpenTimeNotReached(
                s_minimumOpenTime - (block.timestamp - s_startTime)
            );
            // revert Raffle__MinimumOpenTimeNotReached();
        }
        if (s_raffleState != RaffleStates.OPEN) {
            revert Raffle__RaffleNotOpen(s_raffleState);
        }

        s_raffleState = RaffleStates.CALCULATING;

        /**
         * @param i_maximumGasPrice 允许的最大 gas 价格，这里是 30 gWei
         * @param i_subscriptionId 订阅的 VRF 账号ID，详见：https://vrf.chain.link/sepolia
         * @param REQUEST_CONFIRMATIONS 经过确认的区块数，默认交易在3个区块后确认
         * @param i_callbackGasLimit 回调函数的 gas 消耗上限
         * @param NUM_WORDS 请求的随机数数量
         *
         * @dev 回调函数是执行完 requestRandomWords 函数后，紧接着的 fulfillRandomWords 函数
         * @dev 在这笔交易中，我们需要执行两个函数：requestRandomWords 和 fulfillRandomWords
         * @dev 由于交易的原子性，任何一笔函数发生错误，整个交易都会失败。
         */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_maximumGasPrice,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // 合约设计范式：CEI：Checks, Effects, Interactions（检查、效果、交互）
        // 1. Checks：条件判断
        if (s_raffleState != RaffleStates.CALCULATING) {
            revert Raffle__RaffleNotCalculating(s_raffleState);
        }

        // 2.1 Effects：函数核心功能
        s_raffleState = RaffleStates.OPEN;
        uint256 indexOfWinner = randomWords[0] % s_ticketHolders.length;
        address payable winner = s_ticketHolders[indexOfWinner];
        s_recentWinner = winner;

        // 2.2 Effects: 函数收尾部分
        s_ticketHolders = new address payable[](0);
        s_startTime = block.timestamp;

        // 3. Interactions: 合约外部交互
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed(winner);
        }
        emit PickedWinner(winner);
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

    function getMinimumOpenTime() external view returns (uint256) {
        return s_minimumOpenTime;
    }

    function getStartTime() external view returns (uint256) {
        return s_startTime;
    }

    /* block.timestamp 测试 */
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}
