// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract DummyDev is ERC20PresetMinterPauser {
	constructor(uint256 initialSupply, address mintTo)
		ERC20PresetMinterPauser("Dummy Dev", "DDEV")
	{
		_mint(mintTo, initialSupply);
	}
}
