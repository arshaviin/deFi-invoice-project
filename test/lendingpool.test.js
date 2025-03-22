// test/LendingPool.test.js

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LendingPool", function () {
  let deployer, lender, borrower, oracle;
  let invoiceToken, reputationManager, lendingPool;

  beforeEach(async () => {
    [deployer, lender, borrower, oracle] = await ethers.getSigners();

    const ReputationManager = await ethers.getContractFactory("ReputationManager");
    reputationManager = await ReputationManager.deploy();
    await reputationManager.deployed();

    const InvoiceToken = await ethers.getContractFactory("InvoiceToken");
    invoiceToken = await InvoiceToken.deploy();
    await invoiceToken.deployed();

    const LendingPool = await ethers.getContractFactory("LendingPool");
    lendingPool = await LendingPool.deploy(invoiceToken.address, reputationManager.address);
    await lendingPool.deployed();

    await invoiceToken.setLendingPool(lendingPool.address);
  });

  it("should allow minting invoices and funding", async function () {
    const amount = ethers.utils.parseEther("1");
    const interestRate = 1000; // 10%
    const dueDate = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;

    await invoiceToken.connect(borrower).mint("ipfs://invoice123", amount, lender.address, dueDate, interestRate);

    const tokenId = 0;
    await invoiceToken.connect(borrower).approve(lendingPool.address, tokenId);

    await lendingPool.connect(lender).fundInvoice(tokenId, { value: amount });

    const loan = await lendingPool.loans(0);
    expect(loan.amount).to.equal(amount);
    expect(loan.lender).to.equal(lender.address);
    expect(loan.borrower).to.equal(borrower.address);
  });

  it("should reject unauthorized markDefault calls", async function () {
    await expect(lendingPool.connect(borrower).markDefault(0)).to.be.revertedWith("Not authorized");
  });
});
