// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBuyOfferFactory.sol";
import "./BuyOffer.sol";
import "../games/IGames.sol";
import "../filter/IFilterFactory.sol";
import "../filter/FilterStructs.sol";
import "./IBuyOfferVault.sol";
import "../helper/ArrayHelper.sol";
import "./TradingStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuyOfferFactory is IBuyOfferFactory, Ownable {
    // Address of Games contract
    address public gameAddress;
    // Address of Filter factory contract
    address public filterFactoryAddress;
    // Address of BuyOfferVault contract
    address public vaultAddress;

    // gameid => list of all offers
    mapping(uint256 => address[]) private gameOffers;
    // GameId ==> nftAddress ==> List of all offers
    mapping(uint256 => mapping(address => address[])) private nftOffers;
    // Buyer address ==> GameId ==> List of buyer's offers
    mapping(address => mapping(uint256 => address[])) private buyerGameOffers;
    // Buyer address ==> GameId ==> NftAddress => List of buyer's offers
    mapping(address => mapping(uint256 => mapping(address => address[])))
        private buyerGameNftOffers;

    constructor(
        address _gameAddress,
        address _fillterFactoryAddress,
        address _vaultAddress
    ) {
        gameAddress = _gameAddress;
        filterFactoryAddress = _fillterFactoryAddress;
        vaultAddress = _vaultAddress;
    }

    // This event will be raised when we create a BuyOffer
    event BuyOfferCreated(
        uint256 gameId,
        address nftAddress,
        address currency,
        uint256 price,
        string title,
        string description,
        uint256 offerId,
        uint256 filterId,
        address filterAddress,
        address buyOfferAddress,
        address buyerAddress // New
    );

    // This event will be raised when this BuyOffer is done
    event BuyOfferDone(
        uint256 gameId,
        uint256 offerId,
        uint256 counterOfferId,
        address seller,
        uint256 tokenId,
        uint256 price
    );

    // This event will be raised when this BuyOffer is canceled by buyer
    event BuyOfferCanceled(uint256 gameId, uint256 offerId);

    // This event will be raised when seller create a SellOffer to this BuyOffer
    event CounterOfferCreated(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId,
        uint256 amount
    );

    // This event will be raised when seller cancel his SellOffer
    event CounterOfferCancel(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId
    );

    /*******************
     * modifiers
     ********************/

    // Validate gameId
    modifier onlySupportedGame(uint256 _gameId) {
        IGames games = IGames(gameAddress);
        require(games.isSupportedGame(_gameId) == true, "E-0fca0f203");
        _;
    }

    /*******************
     * End modifiers
     ********************/

    /*******************
     * Internal Functions
     ********************/

    function _getOffers(
        address[] memory _offers,
        uint256 _offset,
        uint8 _limit
    ) internal pure returns (address[] memory) {
        uint256 newLimit = ArrayHelper.getLimit(
            _offers.length,
            _offset,
            _limit
        );
        address[] memory offers = new address[](newLimit);

        for (uint256 i = 0; i < newLimit; i++) {
            offers[i] = _offers[i + _offset];
        }

        return offers;
    }

    function _createFilter(
        uint256 _filterId,
        uint256 _gameId,
        address _nftAddress,
        bytes calldata _filterBytecode,
        bytes calldata _signature
    ) internal returns (address) {
        IFilterFactory filterFactory = IFilterFactory(filterFactoryAddress);
        return
            filterFactory.createFilter(
                _filterId,
                _gameId,
                _nftAddress,
                gameAddress,
                _filterBytecode,
                _signature
            );
    }

    function _emitBuyOfferCreated(
        CreateNewOfferParams calldata params,
        uint256 _offerId,
        address _filterAddress,
        address _buyOfferAddress
    ) internal {
        // Emit event
        emit BuyOfferCreated(
            params._gameId,
            params._nftAddress,
            params._currency,
            params._price,
            params._title,
            params._description,
            _offerId,
            params._filterId,
            _filterAddress,
            _buyOfferAddress,
            msg.sender
        );
    }

    /*******************
     * End Internal Functions
     ********************/

    /**
     * @dev Create a new BuyOffer contract. Called by buyer.
     *
     * - Checks:
     *   - Anyone can call.
     *   - GameId must be in a whitelist
     * @param params structure parameter for creating new offer
     */
    function createNewOffer(CreateNewOfferParams calldata params)
        external
        override
        onlySupportedGame(params._gameId)
    {
        require(params._nftAddress != address(0), "E-0fc8765eb");
        require(params._currency != address(0), "E-0fc876aff");
        require(params._price > 0, "E-0fc876fc1");

        // Create a filter contract
        address filterAddress = _createFilter(
            params._filterId,
            params._gameId,
            params._nftAddress,
            params._filterBytecode,
            params._signature
        );

        // offerId should be > 0
        uint256 offerId = gameOffers[params._gameId].length + 1;

        // Create BuyOffer contract
        BuyOffer buyOffer = new BuyOffer(
            params._gameId,
            params._nftAddress,
            msg.sender,
            offerId,
            params._currency,
            params._price,
            params._title,
            params._description,
            filterAddress,
            vaultAddress,
            address(this)
        );
        address buyOfferAddress = address(buyOffer);

        gameOffers[params._gameId].push(buyOfferAddress);
        nftOffers[params._gameId][params._nftAddress].push(buyOfferAddress);
        buyerGameOffers[msg.sender][params._gameId].push(buyOfferAddress);
        buyerGameNftOffers[msg.sender][params._gameId][params._nftAddress].push(
                buyOfferAddress
            );

        IBuyOfferVault buyOfferVault = IBuyOfferVault(vaultAddress);
        buyOfferVault.addNewBuyOffer(buyOfferAddress, msg.sender);

        // Deposit buyer's money
        buyOfferVault.deposit(
            params._currency,
            params._price,
            buyOfferAddress,
            msg.sender
        );

        _emitBuyOfferCreated(params, offerId, filterAddress, buyOfferAddress);
    }

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
    ) external view override returns (address[] memory) {
        return _getOffers(gameOffers[_gameId], _offset, _limit);
    }

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
    ) external view override returns (address[] memory) {
        return _getOffers(nftOffers[_gameId][_nftAddress], _offset, _limit);
    }

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
    ) external view override returns (address[] memory) {
        return
            _getOffers(buyerGameOffers[msg.sender][_gameId], _offset, _limit);
    }

    /**
     * @dev Returns last BuyOffer of user
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     */
    function getMyLastOffers(uint256 _gameId)
        external
        view
        override
        returns (address)
    {
        address[] memory offers = buyerGameOffers[msg.sender][_gameId];
        return offers[offers.length - 1];
    }

    /**
     * @dev Returns last BuyOffer of user
     * @dev In this prototype, it will include even canceled ones.
     * @param _gameId id of the game
     * @param _nft contract address of the NFT
     */
    function getMyLastOffersByNft(uint256 _gameId, address _nft)
        external
        view
        override
        returns (address)
    {
        address[] memory offers = buyerGameNftOffers[msg.sender][_gameId][_nft];
        return offers[offers.length - 1];
    }

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
    ) external view override returns (address[] memory) {
        return
            _getOffers(
                buyerGameNftOffers[msg.sender][_gameId][_nft],
                _offset,
                _limit
            );
    }

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
    ) external override {
        emit BuyOfferDone(
            gameId,
            offerId,
            counterOfferId,
            seller,
            tokenId,
            price
        );
    }

    function emitEventBuyOfferCanceled(uint256 gameId, uint256 offerId)
        external
        override
    {
        emit BuyOfferCanceled(gameId, offerId);
    }

    function emitEventCounterOfferCreated(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId,
        uint256 amount
    ) external override {
        emit CounterOfferCreated(
            gameId,
            buyOfferId,
            sellOfferId,
            seller,
            tokenId,
            amount
        );
    }

    function eventEventCounterOfferCancel(
        uint256 gameId,
        uint256 buyOfferId,
        uint256 sellOfferId,
        address seller,
        uint256 tokenId
    ) external override {
        emit CounterOfferCancel(
            gameId,
            buyOfferId,
            sellOfferId,
            seller,
            tokenId
        );
    }

    function setFilterFactoryAddress(address _filterFactoryAddress)
        external
        override
        onlyOwner
    {
        filterFactoryAddress = _filterFactoryAddress;
    }

    function setVaultAddress(address _vaultAddress)
        external
        override
        onlyOwner
    {
        vaultAddress = _vaultAddress;
    }

    function setGameAddress(address _gameAddress) external override onlyOwner {
        gameAddress = _gameAddress;
    }
}
