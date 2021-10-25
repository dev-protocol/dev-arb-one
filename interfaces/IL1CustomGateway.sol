// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

/*
 * @title Minimum expected interface for L1 custom gateway used https://github.com/OffchainLabs/arbitrum/blob/001bdeecdefbc4eda9a824ef7b39452b46faeb86/packages/arb-bridge-peripherals/contracts/tokenbridge/ethereum/gateway/L1CustomGateway.sol#L100
 */
interface IL1CustomGateway {
    function registerTokenToL2(address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);
}