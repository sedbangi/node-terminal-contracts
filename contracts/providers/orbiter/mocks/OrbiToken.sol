// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ORBIToken is ERC20 {
    constructor() ERC20("Orbiter Tset token", "OBTT") {
        _mint(msg.sender, 99999999999 ether);
    }

    function mint(address toAddress, uint256 amount) public {
        _mint(toAddress, amount * (1 ether));
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount * (1 ether));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
