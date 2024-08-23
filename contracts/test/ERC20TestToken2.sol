// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20TestToken2 is ERC20Upgradeable {
    uint8 private _decimals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 decimals_) public initializer {
        __ERC20_init("ERC20 Test Token", "ETT");
        _decimals = uint8(decimals_);
        _mint(msg.sender, 10 ** 9 * 10 ** decimals_); // 1 billion
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
