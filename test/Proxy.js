const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Proxy", function () {
    let Proxy;
    let proxy;
    let owner;
    let addr1;
    let addr2;
    let implementation;

    beforeEach(async function () {
        // Get the ContractFactories and Signers here.
        const Proxy = await ethers.getContractFactory("Proxy"); 

        [owner , addr1 , addr2] = await ethers.getSigners();


        // Deploy the proxy contract
        proxy = await Proxy.deploy();
    });

    it("should initialize with the correct owner", async function () {
        const tx1 = await proxy._getAdmin();
        expect(tx1).to.equal(owner.address);
    });

    it("should be implemented to correct implementation address", async function(){
        //A dummy implememtation address ---> 0x71bE63f3384f5fb98995898A86B02Fb2426c5788
        await proxy.upgradeTo("0x71bE63f3384f5fb98995898A86B02Fb2426c5788");
        expect(await proxy._getImplementation()).to.equal("0x71bE63f3384f5fb98995898A86B02Fb2426c5788");
    });

    it("To check Admin change is working correct",async function(){
        await proxy.changeAdmin("0xa0Ee7A142d267C1f36714E4a8F75612F20a79720");
        expect(await proxy._getAdmin()).to.equal("0xa0Ee7A142d267C1f36714E4a8F75612F20a79720");
    })

    // Add more tests for upgradeTo, upgradeToAndCall, changeAdmin, etc.
});
