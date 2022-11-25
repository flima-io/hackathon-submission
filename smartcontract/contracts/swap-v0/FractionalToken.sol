// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

// An ERC20 token given when user purchased fractional amount of token.
contract FractionalToken is ERC20, Ownable {
    address _routerAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    event SetRouterAddress(address newAddress);
    // minting and burning token can be called only by pool
    modifier onlyRouter() {
        require(_routerAddress == msg.sender, "E-c500b0e25");
        _;
    }

    function setRouterAddress(address pool) external onlyOwner {
        _routerAddress = pool;
        emit SetRouterAddress(pool);
    }

    mapping(address => bool) _allowedDestinations;

    // only staking pool contract can mint new token to give reward
    function mint(address account, uint256 amount) public onlyRouter {
        _mint(account, amount);
    }

    // only staking pool contract can mint new token to give reward
    function burn(address account, uint256 amount) public onlyRouter {
        _burn(account, amount);
    }
}
