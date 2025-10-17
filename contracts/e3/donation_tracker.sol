// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DonationTracker {
    struct Donation {
        address donor;
        uint256 amount;
        string name;
        string message;
        uint256 timestamp;
    }

    Donation[] public donations;
    uint256 public totalBalance;

    // Donate ETH to the contract
    function donate(string memory donorName, string memory donorMessage) external payable {
        require(msg.value > 0, "Donation must be > 0");

        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            name: donorName,
            message: donorMessage,
            timestamp: block.timestamp
        }));

        totalBalance += msg.value;
    }

    // Withdraw accumulated balance
    function withdraw() external {
        uint256 amount = totalBalance;
        require(amount > 0, "No funds to withdraw");
        totalBalance = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw failed");
    }

    // Get all donation history
    function getDonationHistory() external view returns (Donation[] memory) {
        return donations;
    }
}
