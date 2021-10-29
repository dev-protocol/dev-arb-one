import { ethers, upgrades } from 'hardhat'

async function main() {
	const [deployer] = await ethers.getSigners()
	console.log('Updating contracts with the account:', deployer.address)
	console.log('Account balance:', (await deployer.getBalance()).toString())

	// !please check!!!!!!!!!
	const deployedAddress = '0xb970C9AB82C9b5110d734bA413AA3527ddd9eB6F'
	// !!!!!!!!!!!!!!!!!!!!!!

	const WDEV = await ethers.getContractFactory('ArbDevWrapper')
	await upgrades.upgradeProxy(deployedAddress, WDEV, {
		unsafeAllow: ['delegatecall'],
	})

	console.log('Done')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
