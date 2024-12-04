const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DonationApp Contract", function () {
    let donationApp, owner, addr1, addr2;
    const MINIMUM_USD = ethers.utils.parseEther("0.02"); // Assuming $50 and ETH/USD is ~2500

    beforeEach(async function () {
        // Deploy the contract
        const DonationApp = await ethers.getContractFactory("DonationApp");
        [owner, addr1, addr2] = await ethers.getSigners();

        // Using a mock Chainlink price feed address for testing
        const mockPriceFeedAddress = "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"; // Goerli ETH/USD feed
        donationApp = await DonationApp.deploy(mockPriceFeedAddress);
        await donationApp.deployed();
    });

    it("should only allow the owner to call withdraw()", async function () {
        // Fund the contract with some ETH
        await addr1.sendTransaction({
            to: donationApp.address,
            value: ethers.utils.parseEther("1"), // 1 ETH
        });

        // Ensure that non-owner cannot withdraw
        await expect(donationApp.connect(addr1).withdraw(ethers.utils.parseEther("0.1"))).to.be.revertedWith(
            "Only the owner can perform this action."
        );

        // Ensure the owner can withdraw
        await expect(donationApp.connect(owner).withdraw(ethers.utils.parseEther("0.1"))).to.not.be.reverted;
    });

    it("should revert fund() for donations below the minimum requirement", async function () {
        const lowAmount = ethers.utils.parseEther("0.0001"); // Very small ETH value

        // Ensure the fund function reverts for low donations
        await expect(donationApp.connect(addr1).fund({ value: lowAmount })).to.be.revertedWith("Minimum donation is $50");

        // Ensure valid donations succeed
        const validAmount = ethers.utils.parseEther("0.02"); // Approx $50
        await expect(donationApp.connect(addr1).fund({ value: validAmount })).to.not.be.reverted;
    });

    it("should correctly track donations and funders", async function () {
        const donationAmount = ethers.utils.parseEther("0.05"); // A valid donation

        // Make a donation
        await donationApp.connect(addr1).fund({ value: donationAmount });

        // Check if donation is tracked
        const donationByAddr1 = await donationApp.donationsByAddress(addr1.address);
        expect(donationByAddr1).to.equal(donationAmount);

        // Check if the address is added to funders
        const funders = await donationApp.getFunders();
        expect(funders).to.include(addr1.address);
    });
});
