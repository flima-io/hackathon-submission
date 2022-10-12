// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HeroStructs.sol";
import "./IHero.sol";

contract HeroMock is ERC721Enumerable, Ownable, IHero {
    // Mapping heroId => Hero
    mapping(uint256 => Hero) private idToHeros;

    constructor() ERC721("Dfk HeroMock", "DFKHEROMOCK") {}

    modifier notExisted(uint256 heroId) {
        require(idToHeros[heroId].id == 0, "E-12b4400c9");
        _;
    }

    modifier onlyExisted(uint256 heroId) {
        require(idToHeros[heroId].id == heroId, "E-12bc5c8cb");
        _;
    }

    /**
     * Mint a new NFT with new tokenId to the given address. For testing.
     */
    function mintHero(address recipient, Hero memory hero)
        public
        onlyOwner
        notExisted(hero.id)
        returns (uint256)
    {
        idToHeros[hero.id] = hero;

        _mint(recipient, hero.id);

        return hero.id;
    }

    function getHero(uint256 _id)
        external
        view
        override
        onlyExisted(_id)
        returns (Hero memory)
    {
        return idToHeros[_id];
    }

    function getUserHeroes(address _address)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_address != address(0), "E-12b904345");
        uint256 balanceOf = balanceOf(_address);

        uint256[] memory heroIds = new uint256[](balanceOf);

        for (uint256 i = 0; i < balanceOf; i++) {
            heroIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return heroIds;
    }
}
