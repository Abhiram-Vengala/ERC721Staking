const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyNFT",function(){
    let Mynft ;
    let mynft;
    let owner ;
    let addr1;
    let addr2;

    beforeEach(async function(){
        Mynft = await ethers.getContractFactory("MyNFT");
        mynft = await Mynft.deploy();

        [owner , addr1 , addr2] = await ethers.getSigners();
    });

    it("To check the max supply",async function(){
        expect(await mynft.maxSupply()).to.equal(10000);
    });
    it("To check the min supply",async function(){
        expect(await mynft.minMintAmount()).to.equal(5);
    });

    it("To check it is minting to correct address", async function(){
        await mynft.safeMint(addr1.address,5);
        expect(await mynft.balanceOf(addr1.address)).to.equal(5);
    })

    it("It should not mint more than minMintAmount",async function(){
        expect( mynft.safeMint(addr1.address,6)).to.be.revertedWith("Mint amount should be less than or equal to 5");
    })

    it("It should not mint more than max supply", async function(){
        await mynft.setMaxSupply(5)
        expect( mynft.safeMint(addr1.address,6)).to.be.revertedWith("Total mint amount reached to it's max");
    })

    it("It should check the token owned by the user", async function(){
        await mynft.safeMint(addr1.address,3);
        const tx2 = await mynft.tokenOwnedByUser(addr1.address);
        
        expect(tx2.map(tx=>Number(tx))).to.eql([0,1,2]);
    })
})