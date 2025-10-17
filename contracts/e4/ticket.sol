// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TicketBooking {
    address public organizer;
    uint public ticketPrice;
    uint public totalTickets;
    mapping(address => uint) public ticketsOwned;

    event TicketsPurchased(address indexed buyer, uint quantity, uint totalPrice);
    event TicketsRestocked(uint quantity);

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer");
        _;
    }

    constructor(uint initialTickets, uint pricePerTicket) {
        organizer = msg.sender;
        totalTickets = initialTickets;
        ticketPrice = pricePerTicket;
    }

    // Purchase tickets by sending Ether
    function buyTickets(uint quantity) external payable {
        require(quantity > 0, "Must buy at least 1 ticket");
        require(quantity <= totalTickets, "Not enough tickets available");
        require(msg.value >= quantity * ticketPrice, "Insufficient payment");

        ticketsOwned[msg.sender] += quantity;
        totalTickets -= quantity;

        emit TicketsPurchased(msg.sender, quantity, msg.value);
    }

    // Organizer can restock tickets
    function restockTickets(uint quantity) external onlyOrganizer {
        totalTickets += quantity;
        emit TicketsRestocked(quantity);
    }

    // Check user's ticket balance
    function myTickets() external view returns (uint) {
        return ticketsOwned[msg.sender];
    }

    // Check remaining tickets
    function ticketsRemaining() external view returns (uint) {
        return totalTickets;
    }

    // Withdraw collected funds (organizer only)
    function withdrawFunds() external onlyOrganizer {
        uint amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        (bool sent, ) = organizer.call{value: amount}("");
        require(sent, "Withdraw failed");
    }
}
