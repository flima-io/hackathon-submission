// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./LendingStructs.sol";
import "./ILendingVault.sol";
import "hardhat/console.sol";

/**
 *
 */
contract Lending is Ownable {
    uint256 private immutable gameId;
    // data related to borrower
    BorrowOffer public _offer;
    // a mapping from lender's address to the index of lendOffers array.
    // Note: Even if the user canceled his lendOffer, an entry still exists in this mapping.
    mapping(address => uint32) private lenderIndex;
    // List of lendOffers. Note: index = 0 has empty value because lenderIndex will return zero when the address does not exist.
    LendOffer[] private lendOffers;
    // index of lend offer selected
    uint256 private selectedLendOfferIndex;
    // the timestamp lending started at
    uint256 private lendingStartedAt;
    address private immutable factoryAddress;
    address private immutable vaultAddress;

    using SafeMath for uint256;

    event LendOfferCreated(uint256 borrowOfferId, uint256 lendOfferId);

    event BorrowOfferCanceled(uint256 borrowOfferId);

    event LendOfferCanceled(uint256 borrowOfferId, uint256 lendOfferId);

    constructor(
        uint256 _gameId,
        uint256 _id,
        address _borrower,
        address _collateral,
        uint256 _tokenId,
        address _currency,
        uint256 _amount,
        uint16 _duration,
        uint32 _interestRate,
        address _factoryAddress,
        address _vaultAddress
    ) {
        gameId = _gameId;
        _offer = BorrowOffer(
            _id,
            BorrowOfferStatus.initial,
            _borrower,
            _collateral,
            _tokenId,
            _currency,
            _amount,
            _duration,
            _interestRate
        );
        // because this contract is created by LendingFactory, we have to set owner manually
        _transferOwnership(_borrower);

        // because we use lenderIndex to check if a user already has a lendinfOffer,
        // and mapping returns 0 for nonexistent key, we have to add fake data at index 0
        lendOffers.push(LendOffer(LendOfferStatus.canceled, address(0), 0, 0));
        factoryAddress = _factoryAddress;
        vaultAddress = _vaultAddress;
    }

    function getState() external view returns (BorrowOfferStatus) {
        return _offer.status;
    }

    function getOffer() external view returns (BorrowOffer memory) {
        return _offer;
    }

    /**
     * Get all active lendOffers.
     */
    function getAllActiveLendOffers()
        external
        view
        returns (LendOffer[] memory)
    {
        uint256 countActive = 0;
        for (uint256 i = 1; i < lendOffers.length; i++) {
            if (_isActiveLendOffer(lendOffers[i])) {
                countActive++;
            }
        }
        LendOffer[] memory result = new LendOffer[](countActive);
        uint256 index;
        for (uint256 i = 1; i < lendOffers.length; i++) {
            if (_isActiveLendOffer(lendOffers[i])) {
                result[index] = lendOffers[i];
                index++;
            }
        }
        return result;
    }

    function _isActiveLendOffer(LendOffer storage _lendOffer)
        private
        view
        returns (bool)
    {
        return _lendOffer.status != LendOfferStatus.canceled;
    }

    function createNewLendOffer(uint256 _amount, uint32 _interestRate)
        external
    {
        // borrower can not create lend offer by himself
        require(
            msg.sender != _offer.borrower,
            "E-42092305c"
        );
        require(
            _offer.status == BorrowOfferStatus.initial,
            "E-4209231f0"
        );
        if (lenderIndex[_msgSender()] == 0) {
            // create offer for the first tiem
            uint32 index = uint32(lendOffers.length);
            lenderIndex[_msgSender()] = index;
            lendOffers.push(
                LendOffer(
                    LendOfferStatus.initial,
                    _msgSender(),
                    _amount,
                    _interestRate
                )
            );
        } else {
            // if the user once canceled his offer, he can create new one.
            LendOffer storage _myOffer = _getMyLendOffer();
            require(
                _myOffer.status == LendOfferStatus.canceled,
                "E-42092357d"
            );
            _myOffer.status = LendOfferStatus.initial;
            _myOffer.amount = _amount;
            _myOffer.interestRate = _interestRate;
        }

        // transfer money from lender to contract
        ILendingVault(vaultAddress).depositLoan(
            msg.sender,
            _offer.currency,
            _amount
        );
        emit LendOfferCreated(_offer.id, lenderIndex[_msgSender()]);
    }

    function cancel() external onlyOwner {
        require(
            _offer.status == BorrowOfferStatus.initial,
            "E-4202371f0"
        );
        _offer.status = BorrowOfferStatus.canceled;
        ILendingVault(vaultAddress).cancel(
            msg.sender,
            _offer.collateral,
            _offer.tokenId
        );
        emit BorrowOfferCanceled(_offer.id);
    }

    function chooseLendOffer(address lenderAddress) external onlyOwner {
        uint256 index = lenderIndex[lenderAddress];
        require(index > 0, "E-420ece7e3");
        _offer.status = BorrowOfferStatus.borrowing;

        LendOffer storage lendOffer = lendOffers[index];
        lendOffer.status = LendOfferStatus.selected;
        lendingStartedAt = block.timestamp;
        selectedLendOfferIndex = index;
        ILendingVault(vaultAddress).startLoan(
            _offer.borrower,
            lenderAddress,
            _offer.currency,
            lendOffer.amount
        );
        emit LendOfferCreated(_offer.id, lenderIndex[_msgSender()]);
    }

    /**
     * Functions below are for lenders.
     */
    modifier onlyLender() {
        LendOffer storage _myOffer = _getMyLendOffer();
        require(
            _myOffer.lender == msg.sender,
            "E-420b0dbf1"
        );
        _;
    }

    modifier onlySelectedLender() {
        LendOffer storage _myOffer = _getMyLendOffer();
        require(
            _myOffer.lender == msg.sender &&
                selectedLendOfferIndex == lenderIndex[msg.sender],
            "E-420f0866a"
        );
        _;
    }

    /**
     * Get the lend offer of a person. If there is no offer, abort.
     * Note: one person can have at most one LendOffer for a BorrowOffer.
     */
    function _getMyLendOffer() private view returns (LendOffer storage) {
        uint32 index = lenderIndex[_msgSender()];
        // Note: mapping will return 0 if the key does not exist.
        require(index > 0, "E-4207bf7e3");
        return lendOffers[index];
    }

    function cancelLendOffer() external onlyLender {
        LendOffer storage _myOffer = _getMyLendOffer();
        require(
            _myOffer.status == LendOfferStatus.initial,
            "E-420745fcc"
        );

        ILendingVault(vaultAddress).withdrawLoan(
            msg.sender,
            _offer.currency,
            _myOffer.amount
        );
        _myOffer.status = LendOfferStatus.canceled;
        delete lenderIndex[_msgSender()];
    }

    function deadlinePassed() public view returns (bool) {
        uint256 current = block.timestamp;
        (1 days) * _offer.duration;
        return current > lendingStartedAt + (1 days) * _offer.duration;
    }

    function repayAmount() public view returns (uint256) {
        LendOffer storage lendOffer = lendOffers[selectedLendOfferIndex];
        return lendOffer.amount + calculateInterest();
    }

    function calculateInterest() public view returns (uint256) {
        // TODO
        return 50;
    }

    function repay() external onlyOwner {
        require(_offer.status == BorrowOfferStatus.borrowing, "E-42066ffb2");
        _offer.status = BorrowOfferStatus.repayed;

        LendOffer storage lendOffer = lendOffers[selectedLendOfferIndex];
        uint256 _interest = calculateInterest();
        uint256 _repayAmount = lendOffer.amount + _interest;
        uint256 fee = ((_interest / 100) / 2) * 5;

        ILendingVault(vaultAddress).repay(
            msg.sender,
            _offer.currency,
            lendOffer.lender,
            _repayAmount,
            fee,
            _offer.collateral,
            _offer.tokenId
        );
    }

    function getSelectedLendOffer() external view returns (LendOffer memory) {
        return lendOffers[selectedLendOfferIndex];
    }

    function liquidate() external onlySelectedLender {
        require(_offer.status == BorrowOfferStatus.borrowing, "E-420bcdfb2");
        require(deadlinePassed(), "E-420bcdde3");

        _offer.status = BorrowOfferStatus.liquidated;
        // send NFT to lender
        ILendingVault(vaultAddress).liquidate(
            msg.sender,
            _offer.collateral,
            _offer.tokenId
        );
    }
}
