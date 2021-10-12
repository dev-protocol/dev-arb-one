// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IInbox} from "interfaces/IInbox.sol";
import {IOutbox} from "interfaces/IOutbox.sol";
import {IBridge} from "interfaces/IBridge.sol";

contract Dev is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    address public l2Token;
    address public gateway;
    address public inbox;
    address public devAddress;

    event EscrowMint(address indexed minter, uint256 amount);

    function initialize(address _l2TokenAddr, address _gatewayAddr, address _inbox, address _devAddress) public initializer {
        __ERC20_init("Dev", "DEV");
        l2Token = _l2TokenAddr;
        gateway = _gatewayAddr;
        inbox = _inbox;
        devAddress = _devAddress;
    }

    function escrowMint(uint256 amount) external {
        address msgSender = _l2Sender();
        require(msgSender == l2Token, "sender must be l2 token");
        _mint(gateway, amount);
        emit EscrowMint(msgSender, amount);
    }
    
    function _l2Sender() private view returns (address) {
        IBridge _bridge = IInbox(inbox).bridge();
        require(address(_bridge) != address(0), "bridge is zero address");
        IOutbox outbox = IOutbox(_bridge.activeOutbox());
        require(address(outbox) != address(0), "outbox is zero address");
        return outbox.l2ToL1Sender();
    }

    /**
     * Wrap DEV to create Arbitrum compatible token 
     */
    function wrap(address _tokenAddress, uint256 _amount) external nonReentrant returns (bool) {
        IERC20 _token = IERC20(_tokenAddress);

        require(
            _token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient DEV balance"
        );
        require (address(_token) == devAddress, "Only send DEV");
        _token.safeTransfer(address(this), _amount);
        _mint(msg.sender, _amount);
        return true;
    }

    /**
     * Burn pegged token and return DEV 
     */
    function unwrap() external payable nonReentrant returns (bool) {
        _burn(msg.sender, msg.value);
        IERC20(devAddress).transfer(msg.sender, msg.value);
        return true;
    }
}