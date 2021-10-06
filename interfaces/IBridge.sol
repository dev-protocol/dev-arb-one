//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBridge {
    function activeOutbox() external view returns (address);
}