import { expect } from "chai";
import IIboxABI from "../abi/interfaces/IInbox.sol/IInbox.json";
import IOutboxABI from "../abi/interfaces/IOutbox.sol/IOutbox.json";
import IBridgeABI from "../abi/interfaces/IBridge.sol/IBridge.json";
import { ethers, upgrades, waffle } from "hardhat";

const { deployMockContract } = waffle;

describe("Dev", function () {
  /** TODO - these need to be changed */
  const L2_TOKEN_ADDR = "0x0000000000000000000000000000000000000000";
  const GATEWAY_ADDR = "0x0000000000000000000000000000000000000001";
  /** end TODO */

  before(async function () {
    this.Dev = await ethers.getContractFactory("Dev");
    this.ErcDummy = await ethers.getContractFactory("DummyDev");

    const [, user] = await ethers.getSigners();

    this.mockBridge = await deployMockContract(user, IBridgeABI);
    this.mockInbox = await deployMockContract(user, IIboxABI);
    this.mockOutbox = await deployMockContract(user, IOutboxABI);
  });

  beforeEach(async function () {
    const [, user] = await ethers.getSigners();
    this.ercDummy = await this.ErcDummy.deploy(
      ethers.BigNumber.from(10 ** 8),
      user.address
    );

    await this.ercDummy.deployed();

    this.dev = await upgrades.deployProxy(
      this.Dev,
      [
        L2_TOKEN_ADDR,
        GATEWAY_ADDR,
        this.mockInbox.address,
        this.ercDummy.address,
      ],
      { unsafeAllow: ["delegatecall"] }
    );
    await this.dev.deployed();
  });

  it("Should initialize values", async function () {
    expect(await this.dev.l2Token()).to.equal(L2_TOKEN_ADDR);
    expect(await this.dev.gateway()).to.equal(GATEWAY_ADDR);
    expect(await this.dev.inbox()).to.equal(this.mockInbox.address);
    expect(await this.dev.devAddress()).to.equal(this.ercDummy.address);
  });

  it("Should fail minting when not from l2Token address", async function () {
    await this.mockBridge.mock.activeOutbox.returns(this.mockOutbox.address);

    await this.mockOutbox.mock.l2ToL1Sender.returns(GATEWAY_ADDR); // what should this testing be?

    await this.mockInbox.mock.bridge.returns(this.mockBridge.address);

    expect(this.dev.escrowMint(100)).to.be.revertedWith(
      "sender must be l2 token"
    );
  });

  it("Should fail sending non-DEV to wrap function", async function () {
    const ErcDummy2 = await ethers.getContractFactory("ERC20Upgradeable");
    const ercDummy2 = await upgrades.deployProxy(ErcDummy2);
    await ercDummy2.deployed();
    expect(this.dev.wrap(ercDummy2.address, 1000)).to.be.revertedWith(
      "Only send DEV"
    );
  });

  it("Should fail wrapping due to insufficient DEV balance", async function () {
    const [, , addr2] = await ethers.getSigners();
    this.ercDummy.connect(addr2).approve(this.dev.address, 100);

    expect(
      this.dev.connect(addr2).wrap(this.ercDummy.address, 100)
    ).to.be.revertedWith("Insufficient balance");
  });

  it("Should successfully wrap DEV", async function () {
    const [, user] = await ethers.getSigners();
    const wrapAmount = 100;

    await this.ercDummy.connect(user).approve(this.dev.address, wrapAmount);
    await this.dev.connect(user).wrap(this.ercDummy.address, wrapAmount);

    expect(await this.dev.balanceOf(user.address)).to.eq(wrapAmount);
  });

  it("Should fail unwrapping due to insufficient pegged DEV funds", async function () {
    expect(this.dev.unwrap({ value: 1000 })).to.be.revertedWith(
      "Insufficient balance"
    );
  });
});
