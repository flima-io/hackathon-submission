// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

import "./Lending.sol";
import "./ILending.sol";

contract LendingFactory {
    // gameid => list of all offers
    mapping(uint256 => address[]) private addresses;
    mapping(uint256 => mapping(address => address[])) private addressesByNFT;
    mapping(address => mapping(uint256 => address[])) private offerByBorrower;
    address private immutable vaultAddress;

    constructor(address _vaultAddress) {
        vaultAddress = _vaultAddress;
    }

    event BorrowOfferCreated(
        uint256 gameId,
        uint256 offerId,
        address contractAddress
    );

    function createNewOffer(
        uint256 _gameId,
        address _collateral,
        uint256 _tokenId,
        address _currency,
        uint256 _amount,
        uint16 _duration,
        uint32 _interestRate
    ) external {
        require(_collateral != address(0), "E-da78769a5");
        require(_currency != address(0), "E-da787684e");
        // verify collateral address is in the whitelist of the game
        // verify currency address is in the whitelist of the game
        // verify duration is not too big
        // verify interest rate is not too small, not too big
        // no verification on amount (because it depends on the in-game currency)
        uint256 offerId = addresses[_gameId].length;

        Lending lending = new Lending(
            _gameId,
            offerId,
            msg.sender, 
            _collateral,
            _tokenId,
            _currency,
            _amount,
            _duration,
            _interestRate,
            address(this),
            vaultAddress
        );

        ILendingVault(vaultAddress).addNewLending(address(lending), msg.sender);
        ILendingVault(vaultAddress).depositCollateralNFT(
            address(lending),
            _collateral,
            _tokenId
        );
        address addr = address(lending);
        addresses[_gameId].push(addr);
        addressesByNFT[_gameId][_collateral].push(addr);
        offerByBorrower[msg.sender][_gameId].push(addr);
        emit BorrowOfferCreated(_gameId, offerId, addr);
    }

    function getLastContractAddress(uint256 _gameId)
        external
        view
        returns (address)
    {
        return addresses[_gameId][addresses[_gameId].length - 1];
    }

    function getNumberOfOffers(uint256 _gameId)
        external
        view
        returns (uint256)
    {
        return addresses[_gameId].length;
    }

    function getNumberOfOffers(uint256 _gameId, address _collateral)
        external
        view
        returns (uint256)
    {
        return addressesByNFT[_gameId][_collateral].length;
    }

    function getOne(uint256 _gameId) external pure returns (uint256) {
        return 1;
    }

    /// returns 100 offers
    function getOffers(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory) {
        address[] storage _addresses = addresses[_gameId];
        return _filterAddressByOffset(_addresses, _offset, _limit);
    }

    /// returns 100 offers
    function getOffers(
        uint256 _gameId,
        address _collateral,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory) {
        address[] storage _addresses = addressesByNFT[_gameId][_collateral];
        return _filterAddressByOffset(_addresses, _offset, _limit);
    }

    function _filterAddressByOffset(
        address[] storage _addresses,
        uint256 _offset,
        uint8 _limit
    ) internal view returns (address[] memory) {
        if (_limit == 0) {
            _limit = 10;
        }
        if (_limit > 100) {
            _limit = 100;
        }
        if (_addresses.length < _offset + _limit) {
            _limit = uint8(_addresses.length - _offset);
        }

        address[] memory result = new address[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            result[i] = _addresses[i + _offset];
        }
        return result;
    }

    /**
     * We assume that
     */
    function countMyOffers(uint256 _gameId) external view returns (uint256) {
        address[] storage _addresses = offerByBorrower[msg.sender][_gameId];
        return _addresses.length;
    }

    /**
     * We assume that
     */
    function getMyOffers(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory) {
        address[] storage _addresses = offerByBorrower[msg.sender][_gameId];
        return _filterAddressByOffset(_addresses, _offset, _limit);
    }

    /**
     * We assume that
     */
    function getMyOffers(
        uint256 _gameId,
        address _collateral,
        uint256 _offset,
        uint8 _limit
    ) external view returns (address[] memory) {
        address[] storage _addresses = offerByBorrower[msg.sender][_gameId];
        return _filterAddressByOffset(_addresses, _offset, _limit);
    }
}
