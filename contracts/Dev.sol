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
import {IL1CustomGateway} from "interfaces/IL1CustomGateway.sol";
import {L1MintableToken, ICustomToken} from "interfaces/ICustomToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {TransferAndCallToken} from "./TransferAndCallToken.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// https://github.com/OffchainLabs/arbitrum/blob/master/packages/arb-bridge-peripherals/contracts/tokenbridge/libraries/aeERC20.sol#L21
// removes _setupDecimals since it is no longer used in OZ 0.4

contract aeERC20 is ERC20PermitUpgradeable, TransferAndCallToken, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;

    function _initialize(
        string memory name_,
        string memory symbol_
    ) internal initializer {
        __ERC20Permit_init(name_);
        __ERC20_init(name_, symbol_);
    }
}

contract ArbDEVTokenL1 is aeERC20, ICustomToken {
    using SafeERC20 for IERC20;

    address public bridge;
    bool private shouldRegisterGateway;
    address public devAddress;
    address public gateway;

    // uint8 public constant TEST = uint8(0xa4b1);

    constructor(address _bridge, address _devAddress, address _gateway) public {
        bridge = _bridge;
        aeERC20._initialize("Dev", "DEV");
        devAddress = _devAddress;
        gateway = _gateway;
    }

    function mint() external {
        _mint(msg.sender, 50000000);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20Upgradeable, ICustomToken) returns (bool) {
        return ERC20Upgradeable.transferFrom(sender, recipient, amount);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20Upgradeable, ICustomToken)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(account);
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint16) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        // uint8 public constant TEST = uint8(0xa4b1);
        return uint16(0xa4b1);
        // return TEST;
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
        // address creditBackAddress
    ) public {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        IL1CustomGateway(bridge).registerTokenToL2(
            l2CustomTokenAddress,
            maxGas,
            gasPriceBid,
            maxSubmissionCost
        );

        shouldRegisterGateway = prev;
    }

    /**
     * Wrap DEV to create Arbitrum compatible token 
     */
    function wrap(address _tokenAddress, uint256 _amount) public nonReentrant returns (bool) {
        require (address(_tokenAddress) == devAddress, "Only send DEV");
        IERC20 _token = IERC20(_tokenAddress);
        require(
            _token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient balance"
        );
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        return true;
    }

    function wrapAndBridge(address _tokenAddress, uint256 _amount) external nonReentrant returns (bool) {
        wrap(_tokenAddress, _amount);
        transferFrom(msg.sender, gateway, _amount);
        return true;
    }

    /**
     * Burn pegged token and return DEV 
     */
    function unwrap(uint256 _amount) external payable nonReentrant returns (bool) {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _burn(msg.sender, _amount);
        IERC20(devAddress).transfer(msg.sender, _amount);
        return true;
    }
}

contract MintableArbDEVL1 is L1MintableToken, ArbDEVTokenL1 {

    constructor(address _bridge, address _devAddress, address _gatewayAddress) public ArbDEVTokenL1(_bridge, _devAddress, _gatewayAddress) {}

    function bridgeMint(address account, uint256 amount) public override(L1MintableToken) {
        _mint(account, amount);
    }

    function balanceOf(address account)
        public
        view
        override(ArbDEVTokenL1, ICustomToken)
        returns (uint256 amount)
    {
        return super.balanceOf(account);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ArbDEVTokenL1, ICustomToken) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
