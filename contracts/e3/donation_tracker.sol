// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DonationTracker {
    struct Donation {
        address donor;
        uint amount;
        string name;
        string message;
        uint timestamp;
    }

    mapping(address => Donation[]) private donationsReceived;
    mapping(address => uint) private balances;

    event DonationMade(address indexed donor, address indexed recipient, uint amount, string name, string message);
    event Withdrawal(address indexed recipient, uint amount);

    function donate(address recipient, string memory donorName, string memory donorMessage) external payable {
        require(msg.value > 0, "donation must be > 0");
        donationsReceived[recipient].push(Donation({
            donor: msg.sender,
            amount: msg.value,
            name: donorName,
            message: donorMessage,
            timestamp: block.timestamp
        }));
        balances[recipient] += msg.value;
        emit DonationMade(msg.sender, recipient, msg.value, donorName, donorMessage);
    }

    function withdraw() external {
        uint amount = balances[msg.sender];
        require(amount > 0, "no funds to withdraw");
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdraw failed");
        emit Withdrawal(msg.sender, amount);
    }

    function getDonationHistory(address recipient) external view returns (Donation[] memory) {
        return donationsReceived[recipient];
    }

    function getBalance(address recipient) external view returns (uint) {
        return balances[recipient];
    }
}
