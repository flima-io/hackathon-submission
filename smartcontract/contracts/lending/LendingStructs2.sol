// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/***
 * These structus are for Lending protocol.
 * The lifecycle is as follows.
 * - When borrower wants to borrow, a new Lending contract is created which holds one BorrowOffer
 * - Then lenders come and they create an LendOffer. Multiple offer can come. One user can create only one offer.
 * - Then borrower choose the best offer.
 */

/**
 * borrowing: borrower still borrows the money.
 * repayed: borrower repayed all the borrowed money and got back NFT
 * liquidated: borrower did not repay the money before the deadline. So the NFT is acquired by lender.
 */
enum BorrowOfferStatus {
    initial,
    canceled,
    borrowing,
    repayed,
    liquidated
}

/// @title
/// @author ima
struct BorrowOffer {
    // status
    BorrowOfferStatus status;
    /// the wallet address of borrower
    address borrower;
    /// address of NFT collateral
    address collateral;
    /// id of NFT collateral
    uint256 tokenId;
    /// address of the currency to borrow
    address currency;
    /// amount of currency to borrow
    uint256 amount;
    /// number of days to borrow, maximum 365, minimum 7
    uint16 duration;
    /// expected interest rate per year
    uint32 interestRate;
}

enum BorrowingStatus {
    borrowing,
    repayed,
    liquidated
}

struct BorrowDeal {
    address borrower;
    address lender;
    address currency;
    uint256 amount;
    uint32 interestRate;
}

// all the data per game
struct Game {
    uint256 gameId;
    mapping(address => uint256[]) borrowerIndex;
    Loan[] loans;
}

struct Loan {
    uint256 loanId;
    BorrowOffer offer;
    // a mapping from lender's address to the index of lendOffers array.
    // Note: Even if the user canceled his lendOffer, an entry still exists in this mapping.
    mapping(address => uint32) lenderIndex;
    // List of lendOffers. Note: index = 0 has empty value because lenderIndex will return zero when the address does not exist.
    LendOffer[] lendOffers;
    // index of lend offer selected
    uint256 selectedLendOfferIndex;
    // the timestamp lending started at
    uint256 lendingStartedAt;
}

struct LendOffer {
    LendOfferStatus status;
    /// wallet address of lender
    address lender;
    /// the amount of currency lender sent with this offer
    uint256 amount;
    /// proposed interest rate per year
    uint32 interestRate;
}

/**
 * init: offer is just created. The fund is not yet sent.
 * deposited: fund is sent and the offer is visible to borrower
 * canceled: offer is created by canceled. When canceled, the deposited fund is withdrawn at the same time.
 * selected: selected as offer. The fund is sent to borrower.
 * withdrawn: fund is withdrawn from notselected offer.
 */
enum LendOfferStatus {
    initial,
    canceled,
    selected,
    withdrawn
}
