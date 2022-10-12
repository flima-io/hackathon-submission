// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum BuyOfferStatus {
    initial,
    canceled,
    bought
}

struct BuyOfferData {
    /// a sequential id issued by factory
    uint256 id;
    // Status
    BuyOfferStatus status;
    /// the wallet address of buyer
    address buyer;
    // Title
    string title;
    // Description
    string description;
    /// address of the currency to buy
    address currency;
    /// amount of currency to buy (price)
    uint256 amount;
    // Filter address
    address filterAddress;
}

/**
 * active: offer is just created. Token has been deposited
 * canceled: offer is created by canceled. When canceled, the deposited token is withdrawn at the same time.
 * selected: selected as offer. The token is sent to buyer.
 * withdrawn: token is withdrawn from notselected offer.
 */

enum CounterOfferStatus {
    initial,
    canceled,
    sold
}

struct CounterOffer {
    // Status
    CounterOfferStatus status;
    // wallet address of lender
    address seller;
    // Id of the token for offering to this buy offer
    uint256 tokenId;
    /// the amount of currency seller sent with this offer
    uint256 amount;
}

enum TradeStatus {
    initial,
    deposited,
    canceled,
    done
}

struct Trade {
    // Address of BuyOffer contract
    address buyOfferContractAddress;
    // Wallet address of buyer
    address buyerAddress;
    // Seller address => bool
    mapping(address => bool) canWithdraw;
    // Status of the trade
    TradeStatus status;
}

struct BuyOfferVaultInfo {
    // Address of BuyOffer contract
    address buyOfferContractAddress;
    // Wallet address of buyer
    address buyerAddress;
    // Status of the trade
    TradeStatus status;
}

struct CreateNewOfferParams {
    uint256 _gameId;
    address _nftAddress;
    address _currency;
    uint256 _price;
    string _title;
    string _description;
    uint256 _filterId;
    bytes _filterBytecode;
    bytes _signature;
}
