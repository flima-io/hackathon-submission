// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract MockToken is ERC20 {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from) external {
        _burn(from, balanceOf(from));
    }
}

/**
 * Tokens for testing
 */
contract AXS is MockToken {
    constructor() ERC20("AXS", "AXS") {
        _mint(msg.sender, 10**22);
    }
}

contract JEWEL is MockToken {
    constructor() ERC20("JEWEL", "JEWEL") {
        _mint(msg.sender, 10**24);
    }
}

contract USDT is MockToken {
    constructor() ERC20("USD Tether", "USDT") {
        _mint(msg.sender, 10**24);
    }
}

contract DonateToken is ERC20 {
    constructor() ERC20("DonateToken", "DONATE") {
        _mint(msg.sender, 10**22);
    }
}
