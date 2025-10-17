// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VendingMachine {
    address public owner;
    uint public donutPrice;
    uint public totalDonuts;
    uint public totalSold;
    uint public maxPurchasePerTx = 5;
    mapping(address => uint) public balances;

    event DonutsPurchased(address indexed buyer, uint quantity, uint totalPrice);
    event DonutsRestocked(uint quantity);
    event PriceUpdated(uint newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint initialDonuts, uint initialPrice) {
        owner = msg.sender;
        totalDonuts = initialDonuts;
        donutPrice = initialPrice;
        totalSold = 0;
    }

    // Purchase donuts with ETH
    function purchaseDonuts(uint quantity) external payable {
        require(quantity > 0, "Must purchase at least 1 donut");
        require(quantity <= maxPurchasePerTx, "Exceeds max purchase limit");
        require(totalDonuts >= quantity, "Not enough donuts in stock");
        require(msg.value >= quantity * donutPrice, "Insufficient payment");

        balances[msg.sender] += quantity;
        totalDonuts -= quantity;
        totalSold += quantity;

        emit DonutsPurchased(msg.sender, quantity, msg.value);
    }

    // Owner can restock inventory
    function restockDonuts(uint quantity) external onlyOwner {
        totalDonuts += quantity;
        emit DonutsRestocked(quantity);
    }

    // Owner can update donut price dynamically
    function updatePrice(uint newPrice) external onlyOwner {
        donutPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    // Owner can withdraw collected funds
    function withdrawFunds() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdraw failed");
    }

    // Check current inventory
    function getInventory() external view returns (uint) {
        return totalDonuts;
    }

    // Check total donuts sold
    function getTotalSold() external view returns (uint) {
        return totalSold;
    }
}
