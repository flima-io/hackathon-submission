// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFilterFactory {
    /**
     * Create a new Filter contract from the given bytecode.
     * _signature is a signature to be verified for the _bytecode signed by admin address.
     * Note we can have multiple signers and the signer needs to be identical to any one of them.
     */
    function createFilter(
        uint256 _filterId,
        uint256 _gameId,
        address _nftAddress,
        address _gameAddress,
        bytes calldata _bytecode,
        bytes calldata _signature
    ) external returns (address);

    /**
     * Returns at most 100 filters, filtered by gameId
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getFilters(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * returns at most 100 filters, filtered by gameid and nft
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getFiltersByNft(
        uint256 _gameId,
        address _nft,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * returns at most 100 filters owned by msg.sender, filtered by gameId
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getMyfilters(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * returns at most 100 filters owned by msg.sender, filtered by gameid and nft
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getMyfiltersByNft(
        uint256 _gameId,
        address _nft,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory);

    /**
     * Add a valid signer to verify signature
     * It is used to verify _signature in createFilter()
     * Permission: onlyOwner
     */
    function addSigner(address _signer) external;

    /**
     * Remove a signer from the list of signers.
     * Permission: onlyOwner
     */
    function removeSigner(address _signer) external;
}
