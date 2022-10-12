// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TradingStructs.sol";

interface IBuyOffer {
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
    function cancel() external;

    /**
     * @dev Get the detail of `BuyOffer`
     */
    function getOffer() external view returns (BuyOfferData memory);

    /**
     * Create a new sell offer to this buy offer when they want to propose lower price.
     * Permission: anyone except owner.
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
     */
    function createNewSellOffer(uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev Cancel a sell offer. Can not cancel if the state is already `canceled` or `chosen`.
     * Permission: only those who has an active sellOffer
     *
     * - Checks
     *   - State of the sell-offer must be `initial`
     *   - Only the creator of the sell-offer of the specified NFT token ID can call (must check offer for `_tokenId` is created by `msg.sender`)
     * - Effects
     *   - State of the sell-offer is updated to `canceled` and the data is removed from the storage
     * - Interactions
     *   - NFT is returned from vault to seller
     */
    function cancelSellOffer() external;

    /**
     * Get a list of sell offers. It includes canceled offers.
     */
    function getSellOffers(uint256 _offset, uint8 _limit)
        external
        view
        returns (CounterOffer[] memory);

    /**
     * @dev From multple sellOffers proposed, buyer choose one. The chosen offer must be initial.
     * _index: index of the chosen sell offer in the array
     * - Checks
     *   - State must be `initial`
     *   - Only Buyer can call
     * - Effects
     *   - State is updated to `closed`
     *   - State of sell-offer is updated to `closed`
     * - Interactions
     *   - NFT is sent from vault to Buyer
     *   - Fund is sent from vault to Seller
     */
    function chooseSellOffer(address _sellerAddress) external;

    /**
     * @dev When a sellOffer was not accepted, or when seller wants to cancel the sell offer, withdraw the NFT by calling this function.
     * The specified sellOffer must be active.
     * Permission: only those who has an active sellOffer
     * - Checks
     *   - Only the seller who has the active sell-offer can call
     *   - State of sell-offer is `initial`
     * - Effects
     *   - State of sell-offer is updated to `canceled`
     * - Interactions
     *   - NFT is sent from vault to seller
     */
    // function withdraw() external;
}
