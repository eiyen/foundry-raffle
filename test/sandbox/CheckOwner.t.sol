// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {CheckOwner} from "../../src/sandbox/CheckOwner.sol";

contract CheckOwnerTest is Test {
    CheckOwner public checkOwner;

    function setUp() public {
        checkOwner = new CheckOwner();
    }

    function test_RevertWhen_NotOwner() public {
        console2.log("checkOwner.getOwner:", checkOwner.getOwner());
        console2.log("address(this):      ", address(this));

        // 扮演 msg.sender
        hoax(msg.sender);
        // 检查自定义回滚函数是否符合预期
        vm.expectRevert(
            abi.encodeWithSelector(
                CheckOwner.CheckOwner_NotOwner.selector,
                msg.sender,
                // checkOwner.getOwner() // 为什么在地址一样的情况下，这里使用 CheckOwner.getOwner() 会导致 Call did not revert as expected
                address(this)/*  */
            )
        );
        checkOwner.checkIfOwner();
    }
}
