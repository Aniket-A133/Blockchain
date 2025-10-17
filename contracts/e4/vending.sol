// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DonutVendingMachine {
    address public owner;
    uint public donutPrice;
    uint public totalDonuts;
    mapping(address => uint) public balances;

    event DonutsPurchased(address indexed buyer, uint quantity, uint totalPrice);
    event DonutsRestocked(uint quantity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint initialDonuts, uint pricePerDonut) {
        owner = msg.sender;
        totalDonuts = initialDonuts;
        donutPrice = pricePerDonut;
    }

    // Purchase donuts by sending Ether
    function purchaseDonuts(uint quantity) external payable {
        require(quantity > 0, "Must purchase at least 1 donut");
        require(msg.value >= quantity * donutPrice, "Insufficient payment");
        require(totalDonuts >= quantity, "Not enough donuts in stock");

        balances[msg.sender] += quantity;
        totalDonuts -= quantity;

        emit DonutsPurchased(msg.sender, quantity, msg.value);
    }

    // Owner can restock the vending machine
    function restockDonuts(uint quantity) external onlyOwner {
        totalDonuts += quantity;
        emit DonutsRestocked(quantity);
    }

    // Check vending machine inventory
    function getInventory() external view returns (uint) {
        return totalDonuts;
    }

    // Withdraw accumulated Ether (owner only)
    function withdrawFunds() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdraw failed");
    }
}
