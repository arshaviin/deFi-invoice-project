// test/InvoiceToken.test.js

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("InvoiceToken", function () {
  let deployer, issuer, debtor, lendingPool;
  let invoiceToken;

  beforeEach(async () => {
    [deployer, issuer, debtor, lendingPool] = await ethers.getSigners();

    const InvoiceToken = await ethers.getContractFactory("InvoiceToken");
    invoiceToken = await InvoiceToken.deploy();
    await invoiceToken.deployed();
  });

  it("should mint invoice NFTs with metadata", async function () {
    const amount = ethers.utils.parseEther("5");
    const dueDate = Math.floor(Date.now() / 1000) + 5 * 24 * 60 * 60;
    const interestRate = 1500; // 15%

    await expect(
      invoiceToken.connect(issuer).mint("ipfs://some-uri", amount, debtor.address, dueDate, interestRate)
    ).to.emit(invoiceToken, "Transfer");

    const invoice = await invoiceToken.getInvoice(0);
    expect(invoice.amount).to.equal(amount);
    expect(invoice.debtor).to.equal(debtor.address);
    expect(invoice.interestRate).to.equal(interestRate);
  });

  it("should only allow issuer or lendingPool to mark invoice as paid", async function () {
    const amount = ethers.utils.parseEther("2");
    const dueDate = Math.floor(Date.now() / 1000) + 1 * 24 * 60 * 60;
    const interestRate = 500; // 5%

    await invoiceToken.connect(issuer).mint("ipfs://abc", amount, debtor.address, dueDate, interestRate);

    await expect(
      invoiceToken.connect(debtor).markAsPaid(0)
    ).to.be.revertedWith("Not authorized");

    // simulate lendingPool being set and authorized
    await invoiceToken.connect(deployer).setLendingPool(lendingPool.address);
    await invoiceToken.connect(lendingPool).markAsPaid(0);

    const invoice = await invoiceToken.getInvoice(0);
    expect(invoice.isPaid).to.equal(true);
  });
});
