import { ethers } from "hardhat";

async function main() {
  console.log("Deploying VelyrionMarketplace to Polygon Amoy...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "POL");

  const VelyrionMarketplace = await ethers.getContractFactory("VelyrionMarketplace");
  const marketplace = await VelyrionMarketplace.deploy();

  await marketplace.waitForDeployment();

  const address = await marketplace.getAddress();
  console.log("VelyrionMarketplace deployed to:", address);
  console.log("\nAdd this to your .env files:");
  console.log("CONTRACT_ADDRESS=" + address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
