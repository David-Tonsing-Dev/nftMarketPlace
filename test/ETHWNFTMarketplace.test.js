const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers;

describe("NFTMarketplace", function () {
  let marketplace, nft, token;
  let owner, seller, buyer, creator;

  beforeEach(async function () {
    [owner, seller, buyer, creator] = await ethers.getSigners();

    console.log("🚀 Deploying MockNFT...");
    const NFT = await ethers.getContractFactory("MockNFT");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
    console.log("✅ MockNFT Deployed at:", await nft.getAddress());

    console.log("🚀 Deploying MockERC20...");
    const Token = await ethers.getContractFactory("MockERC20");
    token = await Token.deploy(
      "TestToken",
      "TTK",
      parseEther("1000000"),
      owner.address
    );
    await token.waitForDeployment();
    console.log("✅ MockERC20 Deployed at:", await token.getAddress());

    console.log("🚀 Deploying NFTMarketplace...");
    const Marketplace = await ethers.getContractFactory("NFTMarketplace");
    marketplace = await Marketplace.deploy();
    await marketplace.waitForDeployment();
    console.log(
      "✅ NFTMarketplace Deployed at:",
      await marketplace.getAddress()
    );

    await nft.connect(seller).mint(seller.address);
    console.log("✅ Minted NFT to Seller");
  });

  it("Should allow seller to list and buyer to buy an NFT", async function () {
    console.log("📄 Approving Marketplace...");
    await nft.connect(seller).approve(await marketplace.getAddress(), 0);

    console.log("📄 Listing NFT...");
    await marketplace
      .connect(seller)
      .listNFT(
        await nft.getAddress(),
        0,
        parseEther("1"),
        "0x0000000000000000000000000000000000000000",
        creator.address,
        5
      );

    console.log("📄 Buying NFT...");
    await marketplace
      .connect(buyer)
      .buyNFT(await nft.getAddress(), 0, { value: parseEther("1") });

    expect(await nft.ownerOf(0)).to.equal(buyer.address);
    console.log("✅ NFT successfully transferred to Buyer");
  });

  it("Should allow seller to cancel a listing", async function () {
    await nft.connect(seller).approve(await marketplace.getAddress(), 0);

    await marketplace
      .connect(seller)
      .listNFT(
        await nft.getAddress(),
        0,
        parseEther("1"),
        "0x0000000000000000000000000000000000000000",
        creator.address,
        5
      );

    await marketplace.connect(seller).cancelListing(await nft.getAddress(), 0);

    const listing = await marketplace.listings(await nft.getAddress(), 0);
    expect(listing.seller).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
    console.log("✅ Listing successfully canceled");
  });
});
