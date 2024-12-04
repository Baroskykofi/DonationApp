// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract DonationApp {
    using PriceConverter for uint256;

    address public owner;
    uint256 public totalDonations;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // Minimum donation in USD (scaled to 18 decimals)



    // Constructor to set the deployer as the contract owner
    constructor() {
        owner = msg.sender; // The deployer of the contract is the owner
    }

      // Mapping to track donations per address
    mapping(address => uint256) public donationsByAddress;

       // Array to store unique funders' addresses
    address[] public funders;

     // Event to emit for every donation
    event DonationReceived(address indexed donor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

     // Price feed interface
    AggregatorV3Interface public priceFeed;

        // Modifier to restrict access to owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

     // Fund function to accept ETH donations
    function fund() public payable {
        require(msg.value > 0, "Donation must be greater than zero.");
        
        // Add the donation amount to the sender's record
        if (donationsByAddress[msg.sender] == 0) {
            funders.push(msg.sender); // Add to funders array only if the address is donating for the first time
        }
        donationsByAddress[msg.sender] += msg.value;

        // Update total donations
        totalDonations += msg.value;

        // Emit the donation event
        emit DonationReceived(msg.sender, msg.value);
    }

      // Receive function to handle direct ETH transfers
    receive() external payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Minimum donation is $50"
        );

        if (donationsByAddress[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        donationsByAddress[msg.sender] += msg.value;
        totalDonations += msg.value;

        emit DonationReceived(msg.sender, msg.value);
    }



     // Function to withdraw funds
    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance.");

        // Checks: Ensure the contract has enough funds
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, "Requested amount exceeds balance.");

        // Effects: Update contract state before making external calls
        totalDonations -= amount;

        // Interactions: Transfer the funds to the owner
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed.");

        emit FundsWithdrawn(owner, amount);
    }

    // Function to get the list of funders
    function getFunders() public view returns (address[] memory) {
        return funders;
    }

    // Function to get the balance of the contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}





