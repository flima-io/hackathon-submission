// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./TradingStructs.sol";

// @title IBuyOfferFactory
interface IBuyOfferFactory {
    /**
     * @dev Create a new BuyOffer contract. Called by buyer.
     *
     * Anyone can call.
    
     */
    function createNewOffer(CreateNewOfferParams calldata params) external;

    /**
     * @dev Returns at most 100 buy offers, filtered by gameId and sorted by id. Notice it includes all offers in a game, across all NFTs.
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _offset Offset of the returned result
     * @param _limit Max number of records returned. If more than 100 is specified, it will return only 100 records.
     */
    function getOffers(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * @dev Returns at most 100 buy offers, filtered by NFT and sorted by id.
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _nftAddress contract address of the NFT
     * @param _offset Offset of the returned result
     * @param _limit Max number of records returned. If more than 100 is specified, it will return only 100 records.
     */
    function getOffersByNft(
        uint256 _gameId,
        address _nftAddress,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * @dev Returns at most 100 buy offers of msg.sender, filtered by gameId and sorted by id. Notice it includes all offers in a game, across all NFTs.
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _offset Offset of the returned result
     * @param _limit Max number of records returned. If more than 100 is specified, it will return only 100 records.
     */
    function getMyOffers(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * @dev Returns last BuyOffer of user
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     */
    function getMyLastOffers(
        uint256 _gameId
    ) external view returns (address);

    /**
     * @dev Returns last BuyOffer of user
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _nft contract address of the NFT
     */
    function getMyLastOffersByNft(
        uint256 _gameId,
        address _nft
    ) external view returns (address);

    /**
     * @dev Returns at most 100 buy offers, filtered by NFT and sorted by id.
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _nft contract address of the NFT
     * @param _offset Offset of the returned result
     * @param _limit Max number of records returned. If more than 100 is specified, it will return only 100 records.
     */
    function getMyOffersByNft(
        uint256 _gameId,
        address _nft,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * @dev TheGraph just could listen events based on static address. Then all event from BuyOffer should be emited here
     * @param gameId id of the game
     * @param offerId id of BuyOffer.
     * @param counterOfferId id of SellOffer which was choosed by buyer
     * @param seller address of seller
     * @param tokenId tokenId
     * @param price price to buy
     */
    function emitEventBuyOfferDone(
        uint256 gameId,
        uint256 offerId,
        uint256 counterOfferId,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external;

    function emitEventBuyOfferCanceled (uint256 gameId, uint256 offerId) external;

    function emitEventCounterOfferCreated(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId,
        uint256 amount
    ) external;

    function eventEventCounterOfferCancel(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId
    ) external;

    function setFilterFactoryAddress(
        address _filterFactoryAddress
    ) external;

    function setVaultAddress(
        address _vaultAddress
    ) external;

    function setGameAddress(
        address _gameAddress
    ) external;
}
