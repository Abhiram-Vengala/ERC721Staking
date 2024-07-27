const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NftStaking", function () {
  let NftStaking, nftStaking, MyNFT, myNFT, MyToken, myToken, owner, addr1, addr2;

  beforeEach(async function () {
    // Get the ContractFactories and Signers here.
    MyNFT = await ethers.getContractFactory("MyNFT");
    MyToken = await ethers.getContractFactory("MyToken");
    NftStaking = await ethers.getContractFactory("NftStaking");
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the contracts.
    myNFT = await MyNFT.deploy();

    myToken = await MyToken.deploy();

    nftStaking = await NftStaking.deploy(myNFT.target, myToken.target);
  });

  describe("Deployment", function () {
    it("Should set the NFT and Token addresses correctly", async function () {
      expect(await nftStaking.nft()).to.equal(myNFT.target);
      expect(await nftStaking.token()).to.equal(myToken.target);
    });
  });

  describe("Staking NFTs", function () {
    beforeEach(async function () {
      await myNFT.safeMint(addr1.address, 1);
      await myNFT.connect(addr1).approve(nftStaking.target, 0);
    });

    it("Should allow a user to stake NFTs", async function () {
      await nftStaking.connect(addr1).stake([0]);

      const stakedNft = await nftStaking.stakedNfts(0);

      expect(stakedNft.owner).to.equal(addr1.address); 
      expect(Number(stakedNft.tokenId)).to.equal(0);
      expect(await myNFT.ownerOf(0)).to.equal(nftStaking.target);
    });


    it("Should not allow staking an NFT the user does not own", async function () {
      await nftStaking.connect(addr1).stake([0]);

      await expect(nftStaking.connect(addr2).stake([0])).to.be.revertedWith("You are not the owner");
    });

  });

  describe("Unstaking NFTs", function () {
    beforeEach(async function () {
      await myNFT.safeMint(addr1.address, 1);
      await myNFT.connect(addr1).approve(nftStaking.target, 0);
      await nftStaking.connect(addr1).stake([0]);
    });

    it("Should allow a user to unstake NFTs", async function () {
      await nftStaking.connect(addr1).unStake([0]);

      const stakedNft = await nftStaking.stakedNfts(0);
      expect(stakedNft.owner).to.equal('0x0000000000000000000000000000000000000000');
      expect(await myNFT.ownerOf(0)).to.equal(nftStaking.target);
    });

    it("Should not allow unstaking an NFT the user does not own", async function () {
      await expect(nftStaking.connect(addr2).unStake([0])).to.be.revertedWith("You are not the owner of this NFT");
    });

  });

  describe("Claiming Rewards", function () {
    beforeEach(async function () {
      await myNFT.safeMint(addr1.address, 1);
      await myNFT.connect(addr1).approve(nftStaking.target, 0);
      await nftStaking.connect(addr1).stake([0]);

    });

    it("Should allow a user to claim rewards before delay period", async function () {
      expect(nftStaking.connect(addr1).claim([0])).to.be.revertedWith("Delay period not passed");
    });

    it("Should let you claim ther reward", async function () {
      await nftStaking.connect(owner).setDelayPeriod(0);
      await nftStaking.connect(addr1).claim([0])
      expect(await myToken.balanceOf(addr1)).to.be.greaterThan(0);
    });

  });

  describe("Withdrawing NFTs", function () {
    beforeEach(async function () {
      await myNFT.safeMint(addr1.address, 1);
      await myNFT.connect(addr1).approve(nftStaking.target, 0);
      await nftStaking.connect(addr1).stake([0]);
      await ethers.provider.send("evm_increaseTime", [5 * 60]); // Increase time by 5 minutes
      await ethers.provider.send("evm_mine");
    });

    it("Should allow a user to withdraw  NFTs after unstake", async function () {
      await nftStaking.connect(owner).setUnboundTime(0);
      await nftStaking.connect(addr1).unStake([0]);
      await nftStaking.connect(addr1).withdrawNFTs([0]);
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
    });

    it("Should not allow withdrawing NFTs before the unbound period", async function () {
      await nftStaking.connect(addr1).unStake([0]);
      await expect(nftStaking.connect(addr1).withdrawNFTs([0])).to.be.revertedWith("unbound period not passed ");
    });

    it("Should not allow withdrawing staked NFTs", async function () {
      await expect(nftStaking.connect(addr1).withdrawNFTs([0])).to.be.revertedWith("You can withdraw Nft until you unstake the NFT");
    });
  });
});
