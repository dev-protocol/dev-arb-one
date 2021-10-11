import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Dev", function () {
  /** TODO - these need to be changed */
  const L2_TOKEN_ADDR = "0x0000000000000000000000000000000000000000";
  const GATEWAY_ADDR = "0x0000000000000000000000000000000000000001";
  const INBOX_ADDR = "0x0000000000000000000000000000000000000002";
  /** end TODO */
  let dummyDevAddr = "";

  before(async function () {
    this.Dev = await ethers.getContractFactory("Dev");
    this.ErcDummy = await ethers.getContractFactory("ERC20Upgradeable");
  });

  beforeEach(async function () {
    this.ercDummy = await upgrades.deployProxy(this.ErcDummy);
    console.log("this erc dummy address is: ", this.ercDummy.address);
    dummyDevAddr = this.ercDummy.address;

    this.dev = await upgrades.deployProxy(
      this.Dev,
      [L2_TOKEN_ADDR, GATEWAY_ADDR, INBOX_ADDR, this.ercDummy.address],
      { unsafeAllow: ["delegatecall"] }
    );
    await this.dev.deployed();
    console.log("Wrapped DEV address is: ", this.dev.address);
  });

  it("Should initialize values", async function () {
    expect(await this.dev.l2Token()).to.equal(L2_TOKEN_ADDR);
    expect(await this.dev.gateway()).to.equal(GATEWAY_ADDR);
    expect(await this.dev.inbox()).to.equal(INBOX_ADDR);
    expect(await this.dev.devAddress()).to.equal(dummyDevAddr);
  });

  it("Should fail minting when not from l2Token address", async function () {
    expect(this.dev.escrowMint(100)).to.be.revertedWith(
      "sender must be l2 token"
    );
  });

  // it("Should fail due to insufficient DEV balance", async function () {});

  // it("Should fail sending non-DEV to wrap function", async function () {
  //   const ErcDummy2 = await ethers.getContractFactory("ERC20Upgradeable");
  //   const ercDummy2 = await upgrades.deployProxy(ErcDummy2);
  //   console.log("dummy2 address is: ", ercDummy2.address);

  //   // const success = await this.dev.wrap(ErcDummy2, 1000);

  //   expect(this.dev.wrap(ErcDummy2, 1000)).to.be.revertedWith("Only send DEV");
  // });
});
