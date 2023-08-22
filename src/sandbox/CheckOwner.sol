// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract CheckOwner {
	address immutable private i_owner;
	
	// 自定义错误函数
	error CheckOwner_NotOwner(address caller, address owner);
	
	constructor() {
		i_owner = msg.sender;
	}
	
	function checkIfOwner() external view{
		if (msg.sender != i_owner) {
			// 回滚错误函数
			revert CheckOwner_NotOwner(msg.sender, i_owner);
		}
	}
	
	function getOwner() public view returns(address) {
		return i_owner;
	}
}