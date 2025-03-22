// scripts/oracleUpdater.js

const hre = require("hardhat");

async function main() {
  const [oracle] = await hre.ethers.getSigners();
  console.log("Oracle signer:", oracle.address);

  const lendingPoolAddress = process.env.LENDING_POOL_ADDRESS;
  if (!lendingPoolAddress) throw new Error("Missing LENDING_POOL_ADDRESS in env");

  const LendingPool = await hre.ethers.getContractFactory("LendingPool");
  const lendingPool = LendingPool.attach(lendingPoolAddress);

  const onChainOracle = await lendingPool.defaultOracle();
  if (onChainOracle.toLowerCase() !== oracle.address.toLowerCase()) {
    throw new Error(`Unauthorized: oracle address mismatch. On-chain defaultOracle is ${onChainOracle}`);
  }

  const loanId = parseInt(process.env.LOAN_ID || "0");

  console.log(`Calling markDefault on loanId ${loanId}...`);
  const tx = await lendingPool.markDefault(loanId);
  await tx.wait();
  console.log("Loan marked as default.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
