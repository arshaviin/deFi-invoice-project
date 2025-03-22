// scripts/deploy.js

const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy ReputationManager first
  const ReputationManager = await hre.ethers.getContractFactory("ReputationManager");
  const reputationManager = await ReputationManager.deploy();
  await reputationManager.deployed();
  console.log("ReputationManager deployed to:", reputationManager.address);

  // Deploy InvoiceToken
  const InvoiceToken = await hre.ethers.getContractFactory("InvoiceToken");
  const invoiceToken = await InvoiceToken.deploy();
  await invoiceToken.deployed();
  console.log("InvoiceToken deployed to:", invoiceToken.address);

  // Deploy LendingPool with dependencies
  const LendingPool = await hre.ethers.getContractFactory("LendingPool");
  const lendingPool = await LendingPool.deploy(invoiceToken.address, reputationManager.address);
  await lendingPool.deployed();
  console.log("LendingPool deployed to:", lendingPool.address);

  // Set LendingPool in InvoiceToken
  const tx = await invoiceToken.setLendingPool(lendingPool.address);
  await tx.wait();
  console.log("LendingPool address set in InvoiceToken");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});