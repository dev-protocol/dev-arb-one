//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IInbox} from "interfaces/IInbox.sol";
import {IOutbox} from "interfaces/IOutbox.sol";

contract Dev is ERC20Upgradeable, IInbox, IOutbox, Initializable {
    address public l2Token;
    address public gateway;
    address public inbox;

    event EscrowMint(address indexed minter, uint256 amount);

    function initialize(address _l2TokenAddr, address _gatewayAddr, address _inbox) public initializer {
        __ERC20_init("Dev", "DEV");
        l2Token = _l2TokenAddr;
        gateway = _gatewayAddr;
        inbox = _inbox;
    }

    function escrowMint(uint256 amount) external {
        address msgSender = _l2Sender();
        require(msgSender == l2Token, "sender must be l2 token");
        _mint(gateway, amount);
        emit EscrowMint(msgSender, amount);
    }
    
    function _l2Sender() private view returns (address) {
        IBridge bridge = IInbox(inbox).bridge();
        require(address(bridge) != address(0), "bridge is zero address");
        IOutbox outbox = IOutbox(bridge.activeOutbox());
        require(address(outbox) != address(0), "outbox is zero address");
        return outbox.l2ToL1Sender();
    }
}