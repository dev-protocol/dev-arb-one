// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyDev is ERC20 {

    constructor(uint256 initialSupply, address mintTo) ERC20("Dummy Dev", "DDEV") {
        _mint(mintTo, initialSupply);
    }

}