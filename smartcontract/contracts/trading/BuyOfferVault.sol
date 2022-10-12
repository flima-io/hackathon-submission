/* eslint-disable */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBuyOfferVault.sol";
import "./TradingStructs.sol";

contract BuyOfferVault is IBuyOfferVault, Ownable, IERC721Receiver {
    address private buyOfferFactoryAddress;

    // It is per thousand
    uint256 public feeRate = 25;

    // Our wallet address for receiving fee when a trade to be done
    // TODO: Default it is Flima address
    address public feeAddress = 0xD89fBf940A5F7D2B07Dc2fA08229bB7791C8C33e;

    // Address of BuyOffer => Trade
    mapping(address => Trade) private trades;

    constructor(address _feeAddress) {
        feeAddress = _feeAddress;
    }

    /*******************
     * modifiers
     ********************/
    modifier onlyAddedContract(address buyOfferContractAddress) {
        Trade storage trade = trades[buyOfferContractAddress];

        require(trade.buyOfferContractAddress != address(0), "E-d18c2c7d0");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == buyOfferFactoryAddress, "E-d18922a7a");
        _;
    }

    modifier onlyContract() {
        Trade storage trade = trades[msg.sender];
        require(trade.buyOfferContractAddress == msg.sender, "E-d18d27f2a");
        _;
    }

    modifier onlyBuyer(address buyOfferContractAddress, address buyerAddress) {
        Trade storage trade = trades[buyOfferContractAddress];
        require(trade.buyerAddress == buyerAddress, "E-d18d93ede");
        _;
    }

    modifier onlyBuyerDeposited() {
        Trade storage trade = trades[msg.sender];
        require(trade.status == TradeStatus.deposited, "E-d1847825a");
        _;
    }

    modifier onlySellerDeposited(address _sellerAddress) {
        Trade storage trade = trades[msg.sender];
        require(trade.canWithdraw[_sellerAddress], "E-d186f9612");
        _;
    }

    /*******************
     * End modifiers
     ********************/

    /*******************
     * Internal Functions
     ********************/
    function _calFee(uint256 price) internal view returns (uint256) {
        return (price * feeRate) / 1000;
    }

    function _calPriceAfterFee(uint256 price) internal view returns (uint256) {
        return price - _calFee(price);
    }

    /*******************
     * End Internal Functions
     ********************/

    function setFeeRate(uint256 _feeRate) external override onlyOwner {
        feeRate = _feeRate;
    }

    function setFeeAddress(address _feeAddress) external override onlyOwner {
        feeAddress = _feeAddress;
    }

    function setBuyOfferFactoryAddress(address _buyOfferFactoryAddress)
        external
        override
        onlyOwner
    {
        buyOfferFactoryAddress = _buyOfferFactoryAddress;
    }

    function addNewBuyOffer(
        address buyOfferContractAddress,
        address buyerAddress
    ) external override onlyFactory {
        require(buyOfferContractAddress != address(0), "E-d18a6392c");
        require(buyerAddress != address(0), "E-d18a637ab");

        Trade storage trade = trades[buyOfferContractAddress];

        require(trade.buyOfferContractAddress == address(0), "E-d18a6380c");

        trade.buyOfferContractAddress = buyOfferContractAddress;
        trade.status = TradeStatus.initial;
        trade.buyerAddress = buyerAddress;
    }

    /**
     * Deposit money from seller. Called from BuyOfferFactory.
     * The deposited assets must be stored with msg.sender as the key, which is the address of the BuyOffer.
     * Can be called only once. If there was already an asset, reject request.
     * Permission: from BuyOfferFactory contract.
     */
    function deposit(
        address _currency,
        uint256 _amount,
        address _buyOfferContractAddress,
        address _buyerAddress
    )
        external
        override
        onlyFactory
        onlyAddedContract(_buyOfferContractAddress)
        onlyBuyer(_buyOfferContractAddress, _buyerAddress)
    {
        // Trade status must be in initial state
        require(
            trades[_buyOfferContractAddress].status == TradeStatus.initial,
            "E-d18c3b557"
        );

        trades[_buyOfferContractAddress].status = TradeStatus.deposited;
        IERC20(_currency).transferFrom(_buyerAddress, address(this), _amount);
    }

    function depositNFT(
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId
    ) external override onlyContract {
        Trade storage trade = trades[msg.sender];
        require(trade.status == TradeStatus.deposited, "E-d182d225a");
        require(trade.canWithdraw[_sellerAddress] == false, "E-d182d2de5");

        trade.canWithdraw[_sellerAddress] = true;

        // Send NFT from seller to our contract
        // needs approve before this
        IERC721(_nftAddress).safeTransferFrom(
            _sellerAddress,
            address(this),
            _tokenId
        );
    }

    // Buyer cancel buy offer
    function withdraw(
        address _buyerAddress,
        address _currency,
        uint256 _amount
    )
        external
        override
        onlyContract
        onlyBuyer(msg.sender, _buyerAddress)
        onlyBuyerDeposited
    {
        Trade storage trade = trades[msg.sender];
        trade.status = TradeStatus.canceled;

        // send back money from contract to buyer
        IERC20(_currency).approve(address(this), _amount);
        IERC20(_currency).transferFrom(address(this), _buyerAddress, _amount);
    }

    function withdrawNFT(
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId
    ) external override onlyContract onlySellerDeposited(_sellerAddress) {
        Trade storage trade = trades[msg.sender];
        trade.canWithdraw[_sellerAddress] = false;

        // Send back token from contract to seller
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            _sellerAddress,
            _tokenId
        );
    }

    /**
     * Buyer choose sell offer to finish the buy offer
     * - Checks
     *   - Call from BuyContract
     *   - Buyer has deposited
     *   - Seller has deposited
     *   - Enough money to buy
     *     - deposit >= price --> ok
     *     - deposit + wallet money >= price -> ok
     * - Effects:
     *   - State is updated to done
     *   - Canwithdraw status of seller is updated to false
     * - Interactions
     *   - NFT is sent to buyer
     *   - Money is sent to seller
     *   - Fee is sent to out wallet
     * @param _buyerAddress: Buyer address
     * @param _sellerAddress: Seller address
     * @param _nftAddress: NFT contract address
     * @param _tokenId: Token Id
     * @param _currency: Address of currency
     * @param _depositedAmount: Amount of money that buyer has already deposited
     * @param _sellAmount: Amount of money that buyer must to pay
     */
    function exchange(
        address _buyerAddress,
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId,
        address _currency,
        uint256 _depositedAmount,
        uint256 _sellAmount
    )
        external
        override
        onlyContract
        onlyBuyerDeposited
        onlySellerDeposited(_sellerAddress)
    {
        {
            Trade storage trade = trades[msg.sender];
            trade.status = TradeStatus.done;
            trade.canWithdraw[_sellerAddress] = false;
        }

        if (_depositedAmount < _sellAmount) {
            // Transfer more money from buyer wallet to vault
            // Needs buyer approve before this
            IERC20(_currency).transferFrom(
                _buyerAddress,
                address(this),
                _sellAmount - _depositedAmount
            );
        }

        {
            uint256 _transferAmount = _depositedAmount < _sellAmount
                ? _sellAmount
                : _depositedAmount;
            IERC20(_currency).approve(address(this), _transferAmount);
            // Send funds (after fee) from valt to seller
            uint256 priceAfterFee = _calPriceAfterFee(_sellAmount);
            IERC20(_currency).transferFrom(
                address(this),
                _sellerAddress,
                priceAfterFee
            );
        }

        {
            // Send fee from valt to fee wallet
            // TODO: If we send fee for each trade, it is costly. Let's think
            uint256 fee = _calFee(_sellAmount);
            IERC20(_currency).transferFrom(address(this), feeAddress, fee);
        }

        if (_depositedAmount > _sellAmount) {
            // Return excess money to buyer
            IERC20(_currency).transferFrom(
                address(this),
                _buyerAddress,
                _depositedAmount - _sellAmount
            );
        }

        // Send token to buyer
        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            _buyerAddress,
            _tokenId
        );
    }

    function getBuyOfferVaultStatus(address buyOfferAddress)
        external
        view
        override
        returns (BuyOfferVaultInfo memory)
    {
        Trade storage trade = trades[buyOfferAddress];
        BuyOfferVaultInfo memory buyOfferVaultInfo;

        buyOfferVaultInfo.buyOfferContractAddress = trade
            .buyOfferContractAddress;
        buyOfferVaultInfo.buyerAddress = trade.buyerAddress;
        buyOfferVaultInfo.status = trade.status;

        return buyOfferVaultInfo;
    }

    /**
     * Necessary to hold NFT. See IERC721Receiver.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
