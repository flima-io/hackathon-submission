// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IFilter.sol";
import "../games/DefiKingdom/Hero/HeroProvider.sol";
import "../games/IGames.sol";

import "../games/DefiKingdom/Hero/HeroStructs.sol";

contract Filter_123 is IFilter {
    uint256 public immutable gameId;
    address public immutable nftAddress;
    address public immutable gameAddress;

    constructor(
        uint256 _gameId,
        address _nftAddress,
        address _gameAddress
    ) {
        gameId = _gameId;
        nftAddress = _nftAddress;
        gameAddress = _gameAddress;
    }

    function findProxy() private view returns (HeroProvider) {
        IGames games = IGames(gameAddress);
        address providerAddress = games.findNFTProvider(gameId, nftAddress);
        return HeroProvider(providerAddress);
    }

    /**
     * For given tokenId, ask nftProxy to get the data, and then verify if the NFT satisfy the filter condition.
     */
    function filter(uint256 _tokenId) external view override returns (bool) {
        HeroProvider provider = findProxy();
        Hero memory hero = provider.fetchNFT(_tokenId);
        return hero.summoningInfo.maxSummons > 10 && hero.professions.mining > 4;
    }
}
