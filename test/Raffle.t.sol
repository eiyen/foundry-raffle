// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
// import "forge-std/Test.sol";
import {RaffleScript} from "../script/Raffle.s.sol";
import {Raffle} from "../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    uint256 public startTime;
    uint256 constant TICKET_PRICE = 0.1 ether;
    uint256 constant INSUFFICIENT_FUNDS_FOR_TICKET = 0.01 ether;

    event TicketPurchased(
        uint256 indexed ticketHolderIndex,
        address indexed ticketHolder
    );

    function setUp() public {
        RaffleScript raffleScript = new RaffleScript();
        raffle = raffleScript.run();
        startTime = block.timestamp;
    }

    /**
     * constructor Tests
     */

    /**
     * 笔记：如何调用枚举的值？
     *
     * 1. 通过合约实例，调用存储了枚举中的特定值的状态变量，
     * 例如：raffle.getRaffleState() 返回的 s_raffleState
     * 2. 通过合约类型，直接访问枚举的成员，
     * 例如：Raffle.RaffleStates.OPEN
     */
    function test_InitialRaffleStateShouldBeOPEN() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleStates.OPEN);
    }

    /**
     * buyTicket function Tests
     */

    function test_RevertWhen_TicketPurchaseFundsAreInsuficient() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__InsufficientFundsToPurchaseTicket.selector,
                INSUFFICIENT_FUNDS_FOR_TICKET,
                TICKET_PRICE
            )
        );
        raffle.buyTicket{value: INSUFFICIENT_FUNDS_FOR_TICKET}();
    }

    function test_ShouldPushTicketHolderToArray() public {
        hoax(msg.sender);
        raffle.buyTicket{value: TICKET_PRICE}();

        assert(raffle.getTicketHolder(0) == msg.sender);
    }

    function test_ShouldEmitTicketPurchasedEvent() public {
        hoax(msg.sender);
        vm.expectEmit(true, true, false, false, address(raffle));
        emit TicketPurchased(0, msg.sender);
        raffle.buyTicket{value: TICKET_PRICE}();
    }

    /* 还有当合约状态为 CALCULATING 时，不允许调用 buyTicket 函数的情况还没有测试 */
    /* 这种情况需要在完成 finishCalculating 函数，能够在函数内部切换状态后再去测试 */

    /**
     * pickWinner Test
     */

    /* 测试 block.timestamp 的具体显示 */
    function test_ShouldReturnCurrentBlockTime() public view {
        console2.log("Current block timestamp is ", block.timestamp);
        assert(raffle.getBlockTimestamp() == block.timestamp);
    }

    function test_RevertWhen_MinumumOpenTimeNotReached() public {
        uint256 insufficientEndTime = startTime + raffle.getMinimumOpenTime() - 1;
        hoax(msg.sender);
        vm.warp(insufficientEndTime);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__MinimumOpenTimeNotReached.selector,
                raffle.getMinimumOpenTime() - (insufficientEndTime - startTime)
            )
        );
        raffle.pickWinner();
    }
}
