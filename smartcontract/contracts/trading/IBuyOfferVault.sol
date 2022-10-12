// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TradingStructs.sol";

interface IBuyOfferVault {
    /**
     * @dev Owner set FeeRate
     *
     * - Checks
     *   - Only owner can call
     */
    function setFeeRate(uint256 _feeRate) external;

    /**
     * @dev Owner set Flima Fee Address for sending fee whenever offer to be done
     *
     * - Checks
     *   - Only owner can call
     */
    function setFeeAddress(address _feeAddress) external;

    /**
     * @dev Owner set BuyOfferFactory address
     *
     * - Checks
     *   - Only owner can call
     */
    function setBuyOfferFactoryAddress(address _buyOfferFactoryAddress)
        external;

    /**
     * @dev Create new BuyOffer
     * Permission: anyone except owner.
     * - Checks
     *   - Only BuyOfferFactory can call
     */
    function addNewBuyOffer(
        address buyOfferContractAddress,
        address buyerAddress
    ) external;

    /**
     * Deposit money from _buyerAddress. Called from BuyOffer.
     * The deposited assets must be stored with msg.sender as the key, which is the address of the BuyOffer.
     * Can be called only once. If there was already an asset, reject request.
     * Permission: from BuyOffer contract.
     */
    function deposit(
        address _currency,
        uint256 _amount,
        address _buyOfferContractAddress,
        address _buyerAddress
    ) external;

    /**
     * Deposit money from _sellerAddress. Called from BuyOffer.
     * The deposited assets must be stored with msg.sender as the first key, which is the address of the BuyOffer,
     *  and with tx.origin as the second key, which is the address of the seller
     * It means there is a limitation that seller can create only one sellOffer.
     * Permission: any contract acn call.
     */
    function depositNFT(
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId
    ) external;

    /**
     * Withdraw the money
     * Permission: any contract can call. But the asset it can touch is limited by msg.sender (=contract address).
     */
    function withdraw(
        address _seller,
        address _currency,
        uint256 _amount
    ) external;

    /**
     * Permission: NFT must be filtered by tx.origin (the address) and msg.sender (BuyOffer address) and it needs to match the given _tokenId.
     */
    function withdrawNFT(
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId
    ) external;

    /**
     * When a sellOffer is chosen, the chosen NFT is sent to buyer and the money is sent to the seller.
     * Permission: tx.origin is BuyOffer address. msg.sender must be the owner of the BuyOffer.
     * Permission: NFT must be filtered by tx.origin (the address) and msg.sender (BuyOffer address) and it needs to match the given _tokenId.
     */
    function exchange(
        address _buyerAddress,
        address _sellerAddress,
        address _nftAddress,
        uint256 _tokenId,
        address _currency,
        uint256 _depositedAmount,
        uint256 _sellAmount
    ) external;

    function getBuyOfferVaultStatus(address buyOfferAddress)
        external
        view
        returns (BuyOfferVaultInfo memory);
}
