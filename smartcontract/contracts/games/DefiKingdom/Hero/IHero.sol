// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./HeroStructs.sol";

interface IHero {
    function getHero(uint256 _id) external view returns (Hero memory);

    function getUserHeroes(address _address)
        external
        view
        returns (uint256[] memory);
}
