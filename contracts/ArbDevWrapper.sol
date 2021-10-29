// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IInbox} from "interfaces/IInbox.sol";
import {IOutbox} from "interfaces/IOutbox.sol";
import {IBridge} from "interfaces/IBridge.sol";
import {IGatewayRouter} from "interfaces/IGatewayRouter.sol";
import {IMintRenounceable} from "interfaces/IMintRenounceable.sol";

contract ArbDevWrapper is ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public l2Token;
    address public gateway;
    address public inbox;
    address public devAddress;

    event EscrowMint(address indexed minter, uint256 amount);

    function initialize(address _l2TokenAddr, address _gatewayAddr, address _inbox, address _devAddress) public initializer {
        __ERC20_init("Arb Dev Wrapper", "WDEV");
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
    function wrap(uint256 _amount) public returns (bool) {
        IERC20 _token = IERC20(devAddress);
        require(
            _token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient balance"
        );
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        return true;
    }

    function wrapAndBridge(uint256 _amount, uint256 _maxGas, uint256 _gasPriceBid, bytes calldata _data) external returns (bool) {
        wrap(_amount);
        _approve(msg.sender, gateway, type(uint256).max);
        IGatewayRouter(gateway).outboundTransfer(devAddress, msg.sender, _amount, _maxGas, _gasPriceBid, _data);
        return true;
    }

    /**
     * Burn pegged token and return DEV 
     */
    function unwrap(uint256 _amount) external returns (bool) {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _burn(msg.sender, _amount);
        IERC20(devAddress).safeTransfer(msg.sender, _amount);
        return true;
    }

    /** Safety measure to transfer DEV to owner */
    function transferDev() external onlyOwner returns (bool) {
		IERC20 token = IERC20(devAddress);
		uint256 balance = token.balanceOf(address(this));
		return token.transfer(msg.sender, balance);
	}

    /**
	 * Delete mint role
	 */
	function renounceMinter() external onlyOwner {
		IMintRenounceable(devAddress).renounceMinter();
	}
}