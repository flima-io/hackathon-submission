// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./HeroStructs.sol";
import "./IHero.sol";
import "../../INFTProvider.sol";
import "../../../filter/IFilter.sol";
import "../../../helper/ArrayHelper.sol";

contract HeroProvider /*is INFTProvider*/ {
    address public immutable nftAddress;

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
    }

    function _doFetchNft(uint256 tokenId) internal view returns (Hero memory) {
        require(tokenId >= 0, "E-e1dbc0b1f");
        Hero memory heroData = IHero(nftAddress).getHero(tokenId);

        // return abi.encode(heroData);
        return heroData;
    }

    function fetchNFT(uint256 tokenId)
        external
        view
        // override
        returns (Hero memory)
    {
        require(tokenId > 0, "E-e1d540c83");

        return _doFetchNft(tokenId);
    }

    function fetchUserNFTs(
        address userAddress,
        uint256 offset,
        uint8 limit
    ) external view /*override*/ returns (Hero[] memory) {
        require(userAddress != address(0), "E-e1d48ec24");

        uint256[] memory nftIds = IHero(nftAddress).getUserHeroes(userAddress);

        uint256 newLimit = ArrayHelper.getLimit(nftIds.length, offset, limit);
        Hero[] memory heroData = new Hero[](newLimit);

        for (uint256 i = 0; i < newLimit; i++) {
            heroData[i] = _doFetchNft(nftIds[i + offset]);
            // heroData[i] = IHero(nftAddress).getHero(nftIds[i + offset]);
        }
        return heroData;
    }

    function fetchUserMatchedFilterNfts(
        address userAddress,
        uint256 offset,
        uint8 limit,
        address filterAddress
    ) external view /*override*/ returns (Hero[] memory) {
        require(userAddress != address(0), "E-e1db90c24");
        require(filterAddress != address(0), "E-e1db90253");

        uint256[] memory nftIds = IHero(nftAddress).getUserHeroes(userAddress);
        uint256 newLimit = ArrayHelper.getLimit(nftIds.length, offset, limit);

        Hero[] memory heroData = new Hero[](newLimit);
        uint256 _count = 0;
        IFilter filter = IFilter(filterAddress);
        for (uint256 i = 0; i < nftIds.length; i++) {
            if (_count < newLimit - 1) {
                uint256 nftId = nftIds[i + offset];
                if (filter.filter(nftId)) {
                    heroData[_count] = _doFetchNft(nftId);
                    _count = _count + 1;
                } else {
                    // The nft do not match the filter => do nothing
                }
            } else {
                // We got enough NFT => do nothing
            }
        }

        Hero[] memory matchedHeros = new Hero[](_count);
        for (uint256 index = 0; index < _count; index ++) {
            matchedHeros[index] = heroData[index];
        }

        return matchedHeros;
    }
}
