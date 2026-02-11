import { expect } from "chai";
import hre from "hardhat";

describe("VelyrionMarketplace", function () {
  it("Should deploy successfully", async function () {
    const VelyrionMarketplace = await hre.ethers.getContractFactory("VelyrionMarketplace");
    const marketplace = await VelyrionMarketplace.deploy();
    
    expect(await marketplace.getTotalListings()).to.equal(0);
  });

  it("Should create a listing", async function () {
    const [owner, seller] = await hre.ethers.getSigners();
    
    const VelyrionMarketplace = await hre.ethers.getContractFactory("VelyrionMarketplace");
    const marketplace = await VelyrionMarketplace.deploy();
    
    const dataHash = "QmTest123";
    const qualityProof = JSON.stringify({ rows: 1000, columns: 10 });
    const price = hre.ethers.parseEther("0.01");
    
    await marketplace.connect(seller).createListing(dataHash, qualityProof, price);
    
    expect(await marketplace.getTotalListings()).to.equal(1);
    
    const listing = await marketplace.getListing(1);
    expect(listing.seller).to.equal(seller.address);
    expect(listing.price).to.equal(price);
  });

  it("Should allow purchasing data", async function () {
    const [owner, seller, buyer] = await hre.ethers.getSigners();
    
    const VelyrionMarketplace = await hre.ethers.getContractFactory("VelyrionMarketplace");
    const marketplace = await VelyrionMarketplace.deploy();
    
    await marketplace.connect(seller).createListing(
      "QmTest",
      "{}",
      hre.ethers.parseEther("0.01")
    );
    
    await marketplace.connect(buyer).purchaseData(1, {
      value: hre.ethers.parseEther("0.01")
    });
    
    const purchased = await marketplace.checkPurchaseStatus(1, buyer.address);
    expect(purchased).to.be.true;
  });
});
