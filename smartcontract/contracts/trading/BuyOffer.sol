// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBuyOffer.sol";
import "./TradingStructs.sol";
import "../filter/IFilter.sol";
import "./IBuyOfferVault.sol";
import "./IBuyOfferFactory.sol";
import "../helper/ArrayHelper.sol";

contract BuyOffer is Ownable, IBuyOffer {
    // Game Id
    uint256 private immutable gameId;

    // Nft address
    address public immutable nftAddress;

    // Address of BuyOfferVault contract
    address public immutable vaultAddress;

    // Address of BuyOfferFactory contract.
    // Because of TheGraph problem, we need emit event from BuyOfferFactory
    // TODO: It should be removed when TheGraph is fixed
    address public immutable buyOfferFactoryAddress;

    // Data related to the buy offer
    BuyOfferData public buyOfferData;

    // List of SellOffer. Note: index = 0 has empty value because lenderIndex will return zero when the address does not exist.
    CounterOffer[] private sellOffers;

    // a mapping from seller's address to the index of sellOffers array.
    // Note: Even if the user canceled his lendOffer, an entry still exists in this mapping.
    mapping(address => uint256) private sellerIndex;

    // index of lend offer selected
    uint256 private selectedSellOfferIndex;

    // This event will be raised when this BuyOffer is canceled by buyer
    event BuyOfferCanceled(uint256 gameId, uint256 offerId);

    // This event will be raised when this BuyOffer is done
    event BuyOfferDone(
        uint256 gameId,
        uint256 offerId,
        uint256 counterOfferId,
        address seller,
        uint256 tokenId,
        uint256 price
    );

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

    constructor(
        uint256 _gameId,
        address _nftAddress,
        address _buyerAddress,
        uint256 _id,
        address _currency,
        uint256 _price,
        string memory _title,
        string memory _description,
        address _filterAddress,
        address _vaultAddress,
        address _buyOfferFactoryAddress
    ) {
        gameId = _gameId;
        nftAddress = _nftAddress;
        vaultAddress = _vaultAddress;
        buyOfferFactoryAddress = _buyOfferFactoryAddress;

        buyOfferData = BuyOfferData(
            _id,
            BuyOfferStatus.initial,
            _buyerAddress,
            _title,
            _description,
            _currency,
            _price,
            _filterAddress
        );

        // because we use sellerIndex to check if a user already has a CounterOffer,
        // and mapping returns 0 for nonexistent key, we have to add fake data at index 0
        sellOffers.push(
            CounterOffer(CounterOfferStatus.canceled, address(0), 0, 0)
        );

        // because this contract is created by BuyOfferFactory, we have to set owner manually
        _transferOwnership(_buyerAddress);
    }

    /*******************
     * Internal Functions
     ********************/

    /**
     * Get the sell offer of a person. If there is no offer, abort.
     * Note: one person can have at most one SellOffer for a BuyOffer.
     */
    function _getMySellOffer() private view returns (CounterOffer storage) {
        return _getSellOffer(_msgSender());
    }

    /**
     * Get the sell offer of a person. If there is no offer, abort.
     * Note: one person can have at most one SellOffer for a BuyOffer.
     */
    function _getSellOffer(address seller)
        private
        view
        returns (CounterOffer storage)
    {
        uint256 index = sellerIndex[seller];
        // Note: mapping will return 0 if the key does not exist.
        require(sellOffers[index].seller == seller, "E-8b9e2d7e3");
        return sellOffers[index];
    }

    function _haveGotSellOffer(address seller) private view returns (bool) {
        return sellerIndex[seller] > 0;
    }

    function _validateNft(uint256 _tokenId) private view returns (bool) {
        IFilter filter = IFilter(buyOfferData.filterAddress);
        return filter.filter(_tokenId);
    }

    function _emitBuyOfferDone(
        uint256 counterOfferId,
        address seller,
        uint256 tokenId,
        uint256 price
    ) private {
        // Still emit event here
        emit BuyOfferDone(
            gameId,
            buyOfferData.id,
            counterOfferId,
            seller,
            tokenId,
            price
        );

        // Because of TheGraph problem, we also emit event from BuyOfferFactory
        IBuyOfferFactory buyOfferFactory = IBuyOfferFactory(
            buyOfferFactoryAddress
        );
        buyOfferFactory.emitEventBuyOfferDone(
            gameId,
            buyOfferData.id,
            counterOfferId,
            seller,
            tokenId,
            price
        );
    }

    function _emitBuyOfferCanceled(uint256 offerId) private {
        emit BuyOfferCanceled(gameId, offerId);

        // Because of TheGraph problem, we also emit event from BuyOfferFactory
        IBuyOfferFactory buyOfferFactory = IBuyOfferFactory(
            buyOfferFactoryAddress
        );
        buyOfferFactory.emitEventBuyOfferCanceled(gameId, offerId);
    }

    function _emitCounterOfferCreated(uint256 _tokenId, uint256 _amount)
        private
    {
        emit CounterOfferCreated(
            gameId,
            buyOfferData.id,
            sellerIndex[_msgSender()],
            _msgSender(),
            _tokenId,
            _amount
        );

        // Because of TheGraph problem, we also emit event from BuyOfferFactory
        IBuyOfferFactory buyOfferFactory = IBuyOfferFactory(
            buyOfferFactoryAddress
        );
        buyOfferFactory.emitEventCounterOfferCreated(
            gameId,
            buyOfferData.id,
            sellerIndex[_msgSender()],
            _msgSender(),
            _tokenId,
            _amount
        );
    }

    function _emitCounterOfferCancel(uint256 sellOfferId, uint256 tokenId)
        private
    {
        emit CounterOfferCancel(
            gameId,
            buyOfferData.id,
            sellOfferId,
            _msgSender(),
            tokenId
        );

        // Because of TheGraph problem, we also emit event from BuyOfferFactory
        IBuyOfferFactory buyOfferFactory = IBuyOfferFactory(
            buyOfferFactoryAddress
        );
        buyOfferFactory.eventEventCounterOfferCancel(
            gameId,
            buyOfferData.id,
            sellOfferId,
            _msgSender(),
            tokenId
        );
    }

    /*******************
     * End Internal Functions
     ********************/

    /*******************
     * modifiers
     ********************/

    modifier onlyNftMatchedFilter(uint256 _tokenId) {
        require(_validateNft(_tokenId) == true, "E-8b9f993c2");
        _;
    }

    modifier onlySeller() {
        CounterOffer storage sellOffer = _getMySellOffer();
        require(sellOffer.status == CounterOfferStatus.initial, "E-8b9512f9e");
        _;
    }

    modifier sellerMustExisted(address seller) {
        require(_haveGotSellOffer(seller) == true);
        _;
    }

    /*******************
     * End modifiers
     ********************/

    /**
     * @dev Buyer cancel the offer.
     *
     * - Checks
     *   - Can cancel only when it is in the initial state
     *   - Only contract owner can cancel
     * - Effects
     *   - State is updated to canceled
     * - Interactions
     *   - Deposited funds will be returned from vault to buyer
     */
    function cancel() external override onlyOwner {
        // Validate offer status
        require(buyOfferData.status == BuyOfferStatus.initial, "E-8b9237f41");

        // Change offer status
        buyOfferData.status = BuyOfferStatus.canceled;

        // Send money back to buyer
        IBuyOfferVault buyOfferVault = IBuyOfferVault(vaultAddress);
        buyOfferVault.withdraw(
            msg.sender,
            buyOfferData.currency,
            buyOfferData.amount
        );

        _emitBuyOfferCanceled(buyOfferData.id);
    }

    /**
     * @dev Get the detail of `BuyOffer`
     */
    function getOffer() external view override returns (BuyOfferData memory) {
        return buyOfferData;
    }

    /**
     * Create a new sell offer to this buy offer when they want to propose higher price.
     * Permission: anyone except owner (Seller call).
     * - Checks
     *   - State must be initial
     *   - The NFT satisfies the buyer's requirement
     *   - Buyer can not create a sell-offer by himself
     *   - A seller can not create >= 2 sell-offers
     * - Effects
     *   - A new sell-offer is created
     * - Interactions
     *   - NFT is sent from seller to vault
     * @param _tokenId The id of the NFT
     * @param _amount Expected price
     */
    function createNewSellOffer(uint256 _tokenId, uint256 _amount)
        external
        override
        onlyNftMatchedFilter(_tokenId)
    {
        // Buyer can not create sell offer by himself
        require(_msgSender() != buyOfferData.buyer, "E-8b95c373e");
        require(buyOfferData.status == BuyOfferStatus.initial, "E-8b95c3f41");

        if (!_haveGotSellOffer(_msgSender())) {
            // The seller has not got any sell offer for this buy offer yet
            // => create new sell offer
            sellerIndex[_msgSender()] = sellOffers.length;
            CounterOffer memory sellOffer = CounterOffer(
                CounterOfferStatus.initial,
                _msgSender(),
                _tokenId,
                _amount
            );
            sellOffers.push(sellOffer);
        } else {
            // if the user once canceled his offer, he can update and active his offer again.
            CounterOffer storage sellOffer = _getMySellOffer();
            require(
                sellOffer.status == CounterOfferStatus.canceled,
                "E-8b95c3c2d"
            );

            sellOffer.status = CounterOfferStatus.initial;
            sellOffer.amount = _amount;
            sellOffer.tokenId = _tokenId;
        }

        // Deposit seller's nft
        IBuyOfferVault(vaultAddress).depositNFT(
            _msgSender(),
            nftAddress,
            _tokenId
        );

        _emitCounterOfferCreated(_tokenId, _amount);
    }

    /**
     * Cancel a sell offer.
     * Permission: anyone except owner.
     * - Checks
     *   - State must be initial
     *   - Only seller can cancel a sell-offer by himself
     * - Effects
     *   - Sell-offer status is changed to cancel
     * - Interactions
     *   - Withdraw NFT: NFT is sent from vault to seller
     */
    function cancelSellOffer() external override onlySeller {
        CounterOffer storage sellOffer = _getMySellOffer();
        uint256 index = sellerIndex[_msgSender()];

        sellOffer.status = CounterOfferStatus.canceled;
        IBuyOfferVault(vaultAddress).withdrawNFT(
            _msgSender(),
            nftAddress,
            sellOffer.tokenId
        );

        _emitCounterOfferCancel(index, sellOffer.tokenId);
    }

    /**
     * Get a list of sell offers. It includes canceled offers.
     */
    function getSellOffers(uint256 _offset, uint8 _limit)
        external
        view
        override
        returns (CounterOffer[] memory)
    {
        // return sellOffers;
        uint256 newLimit = ArrayHelper.getLimit(
            sellOffers.length,
            _offset,
            _limit
        );
        // Do not return default counter offer at index of 0
        if (newLimit > 0) {
            newLimit = newLimit - 1;
        }
        CounterOffer[] memory offers = new CounterOffer[](newLimit);

        for (uint256 i = 0; i < newLimit; i++) {
            offers[i] = sellOffers[i + 1 + _offset];
        }

        return offers;
    }

    /**
     * Buyer choose a sell offer.
     * Permission: Only buyer.
     * - Checks
     *   - State must be initial
     *   - Only buyer can do on his own Buy Offer by himself
     * - Effects
     *   - Buy-offer status is changed to bought
     * - Interactions
     *   - NFT is sent from vault to buyer
     *   - Money is sent from vault to seller
     *   - Fee is sent from vault to our wallet
     * @param _sellerAddress Address of a seller
     */
    function chooseSellOffer(address _sellerAddress)
        external
        override
        onlyOwner
        sellerMustExisted(_sellerAddress)
    {
        uint256 index = sellerIndex[_sellerAddress];

        require(buyOfferData.status == BuyOfferStatus.initial, "E-8b9802f41");

        CounterOffer storage sellOffer = _getSellOffer(_sellerAddress);
        require(sellOffer.status == CounterOfferStatus.initial, "E-8b9802f9e");

        // Validate NFT again. The NFT may changed during deposited time.
        require(_validateNft(sellOffer.tokenId) == true, "E-8b9802ce9");

        buyOfferData.status = BuyOfferStatus.bought;
        sellOffer.status = CounterOfferStatus.sold;

        IBuyOfferVault(vaultAddress).exchange(
            buyOfferData.buyer,
            _sellerAddress,
            nftAddress,
            sellOffer.tokenId,
            buyOfferData.currency,
            buyOfferData.amount,
            sellOffer.amount
        );

        _emitBuyOfferDone(
            index,
            sellOffer.seller,
            sellOffer.tokenId,
            sellOffer.amount
        );
    }

    /**
     * @dev When a sellOffer was not accepted, or when seller wants to cancel the sell offer, withdraw the NFT by calling this function.
     * The specified sellOffer must be active.
     * Permission: only those who has an active sellOffer
     * - Checks
     *   - Only the seller who has the active sell-offer can call
     *   - State of sell-offer is `initial`
     * - Effects
     *   - State of sell-offer is updated to `withdrawed`
     * - Interactions
     *   - NFT is sent from vault to seller
     */
    // function withdraw() external override onlySeller {
    //   CounterOffer storage sellOffer = _getMySellOffer();
    //   uint256 index = sellerIndex[_msgSender()];

    //   sellOffer.status = CounterOfferStatus.withdrawed;
    //   IBuyOfferVault(vaultAddress).withdrawNFT(_msgSender(), nftAddress, sellOffer.tokenIdtokenId);

    //   emit CounterOfferCancel(gameId, buyOfferData.id, index, _msgSender(), sellOffer.tokenIdtokenId);
    // }
}
