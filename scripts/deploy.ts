/* eslint-disable no-process-exit */
import { ethers, upgrades } from "hardhat";

async function main() {
  // const decimals = ethers.BigNumber.from(10).pow(18);
  // const initialSupply = ethers.BigNumber.from(10).pow(7).mul(decimals); // 10 mil DEV
  // !please check!!!!!!!!!
  const l1DevAddress = "0xa21cb351fc29acb7c3901270a5259bf5e68f11d8"; // This is Rinkeby Dummy DEV value
  const l2DevAddress = "0xc28BBE3B5ec1b06FDe258864f12c1577DaDFadDC";
  const gatewayAddress = "0x9b014455AcC2Fe90c52803849d0002aeEC184a06";
  const inboxAddress = "0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e";

  // address _l2TokenAddr, address _gatewayAddr, address _inbox, address _devAddress
  // !!!!!!!!!!!!!!!!!!!!!!

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
  const Dev = await ethers.getContractFactory("Dev");
  const dev = await upgrades.deployProxy(
    Dev,
    [l2DevAddress, gatewayAddress, inboxAddress, l1DevAddress],
    { unsafeAllow: ["delegatecall"] }
  );

  await dev.deployed();

  console.log("Dev deployed to:", dev.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
