import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Dev", function () {
  /** TODO - these need to be changed */
  const L2_TOKEN_ADDR = "0x0000000000000000000000000000000000000000";
  const GATEWAY_ADDR = "0x0000000000000000000000000000000000000001";
  const INBOX_ADDR = "0x0000000000000000000000000000000000000002";
  /** end TODO */

  before(async function () {
    this.Dev = await ethers.getContractFactory("Dev");
  });

  beforeEach(async function () {
    this.dev = await upgrades.deployProxy(
      this.Dev,
      [L2_TOKEN_ADDR, GATEWAY_ADDR, INBOX_ADDR],
      {}
    );
    await this.dev.deployed();
  });

  it("Should initialize values", async function () {
    expect(await this.dev.l2Token()).to.equal(L2_TOKEN_ADDR);
    expect(await this.dev.gateway()).to.equal(GATEWAY_ADDR);
    expect(await this.dev.inbox()).to.equal(INBOX_ADDR);
  });

  it("Should fail minting when not from l2Token address", async function () {
    expect(this.dev.escrowMint(100)).to.be.revertedWith(
      "sender must be l2 token"
    );
  });
});
