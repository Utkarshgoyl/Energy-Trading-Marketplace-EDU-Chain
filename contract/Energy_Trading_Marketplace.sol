// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract EnergyTradingMarketplace {
    enum Role { None, Producer, Consumer }

    struct User {
        Role role;
        uint256 energyBalance; // in kWh
        uint256 walletBalance; // in wei
    }

    struct Trade {
        address producer;
        address consumer;
        uint256 energyAmount; // in kWh
        uint256 pricePerKWh;  // in wei
        bool completed;
    }

    uint256 public tradeCount;
    mapping(address => User) public users;
    mapping(uint256 => Trade) public trades;

    modifier onlyRegistered() {
        require(users[msg.sender].role != Role.None, "User not registered");
        _;
    }

    function registerProducer() external {
        require(users[msg.sender].role == Role.None, "Already registered");
        users[msg.sender].role = Role.Producer;
    }

    function registerConsumer() external {
        require(users[msg.sender].role == Role.None, "Already registered");
        users[msg.sender].role = Role.Consumer;
    }

    function depositEnergy(uint256 _amount) external onlyRegistered {
        require(users[msg.sender].role == Role.Producer, "Only producers can deposit energy");
        users[msg.sender].energyBalance += _amount;
    }

    function depositFunds() external payable onlyRegistered {
        users[msg.sender].walletBalance += msg.value;
    }

    function createTrade(address _consumer, uint256 _energyAmount, uint256 _pricePerKWh) external onlyRegistered {
        require(users[msg.sender].role == Role.Producer, "Only producers can create trades");
        require(users[msg.sender].energyBalance >= _energyAmount, "Insufficient energy");
        require(users[_consumer].role == Role.Consumer, "Invalid consumer");

        trades[tradeCount] = Trade({
            producer: msg.sender,
            consumer: _consumer,
            energyAmount: _energyAmount,
            pricePerKWh: _pricePerKWh,
            completed: false
        });

        tradeCount++;
        users[msg.sender].energyBalance -= _energyAmount;
    }

    function completeTrade(uint256 _tradeId) external onlyRegistered {
        Trade storage trade = trades[_tradeId];

        require(!trade.completed, "Trade already completed");
        require(msg.sender == trade.consumer, "Only assigned consumer can complete this trade");

        uint256 totalPrice = trade.energyAmount * trade.pricePerKWh;
        require(users[msg.sender].walletBalance >= totalPrice, "Insufficient funds");

        users[msg.sender].walletBalance -= totalPrice;
        users[trade.producer].walletBalance += totalPrice;

        users[msg.sender].energyBalance += trade.energyAmount;
        trade.completed = true;
    }

    function withdrawFunds() external onlyRegistered {
        uint256 balance = users[msg.sender].walletBalance;
        require(balance > 0, "No funds to withdraw");

        users[msg.sender].walletBalance = 0;
        payable(msg.sender).transfer(balance);
    }

    function getUserDetails(address _user) external view returns (Role, uint256, uint256) {
        User memory user = users[_user];
        return (user.role, user.energyBalance, user.walletBalance);
    }

    function getTradeDetails(uint256 _tradeId) external view returns (address, address, uint256, uint256, bool) {
        Trade memory trade = trades[_tradeId];
        return (trade.producer, trade.consumer, trade.energyAmount, trade.pricePerKWh, trade.completed);
    }
}

