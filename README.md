## 合约逻辑

项目合约 Raffle.sol 核心是运用 **Chainlink VRF** 提供的随机数**进行抽奖**，并利用 **Chainlink Automation** 提供的自动执行合约函数的功能**定期抽奖**。

合约的实现逻辑如下：

1. 参与抽奖：设置一个参与抽奖的函数，当用户通过该函数转账超过门票的金额后，即可参与抽奖。
2. 开奖条件：设置开奖条件，只有当处于开奖状态、且经过了一段时间、且有玩家参与、且合约有余额的情况下，才能够开奖。
3. 进行抽奖：在达成开奖条件的情况下，通过 Chainlink VRF 获得随机数。
4. 奖金转账：让随机数和参与玩家的数量取模，余数即为中奖者的序号，然后再取得该玩家的地址，最后进行转账。

> 计划：
> 
> 1. 在代码解释中，分别补充对 Chainlink VRF 和 Automation 原理和写法的解释。
> 2. 完成对部署逻辑和测试逻辑的解释。