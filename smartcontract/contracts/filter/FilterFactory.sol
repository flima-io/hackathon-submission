// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFilterFactory.sol";
import "../helper/AddressHelper.sol";
import "../helper/ChainHelper.sol";
import "../games/IGames.sol";


contract FilterFactory is IFilterFactory, Ownable {

    // signerAddress => true/false
    mapping(address => bool) private signers;
    // gameId => nft => deployed address => boolean
    mapping(uint256 => mapping(address => mapping(address => bool))) private deployedAddresses;
    // gameId => list of all filter contract addresses
    mapping(uint256 => address[]) private addresses;
    // gameId => nft => filter contract addresses
    mapping(uint256 => mapping(address => address[])) private addressesByNft;
    // filter creator => gameId => filter contract addresses
    mapping(address => mapping(uint256 => address[])) private filtersByOwner;
    // filter creator => gameId => nft => filter contract addresses
    mapping(address => mapping(uint256 => mapping(address => address[]))) private filtersByNftAndOwner;

    event FilterContractCreated(uint256 indexed filterId, address contractAddress);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    /**
     * Create a new Filter contract from the given bytecode
     */
    function createFilter(
        uint256 _filterId,
        uint256 _gameId,
        address _nftAddress,
        address _gameAddress,
        bytes calldata _bytecode,
        bytes calldata _signature
    )
        external
        override
        returns (address)
    {
        // verify filterId
        require(_filterId > 0, "E-3e438b4da");
        // verify nftAddress
        require(_nftAddress != address(0), "E-3e438b191");
        // verify gameAddress
        require(_gameAddress != address(0), "E-3e438bb13");
        // verify active gameId
        require(IGames(_gameAddress).isSupportedGame(_gameId) == true, "E-3e438b3f7");
        // verify gameId + nftAddress belongs to whitelist
        require(IGames(_gameAddress).isValidERC721(_gameId, _nftAddress) == true, "E-3e438b4dd");

        uint256 _chainId = ChainHelper.chainId();
        verifySigner(_nftAddress, _chainId, _bytecode, _signature);

        address deployedAddress = deployContract(_gameId, _nftAddress, _gameAddress, _chainId, _bytecode);

        addresses[_gameId].push(deployedAddress);
        addressesByNft[_gameId][_nftAddress].push(deployedAddress);
        filtersByOwner[msg.sender][_gameId].push(deployedAddress);
        filtersByNftAndOwner[msg.sender][_gameId][_nftAddress].push(deployedAddress);
        deployedAddresses[_gameId][_nftAddress][deployedAddress] = true;

        emit FilterContractCreated(_filterId, deployedAddress);

        return deployedAddress;
    }

    /**
     * Returns at most 100 filters, filtered by gameId
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getFilters(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    )
        external
        view
        override
        returns (address[] memory)
    {
        address[] storage _addresses = addresses[_gameId];
        return AddressHelper.filterAddressByOffset(_addresses, _offset, _limit);
    }

    /**
     * returns at most 100 filters, filtered by gameid and nft
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getFiltersByNft(
        uint256 _gameId,
        address _nft,
        uint256 _offset,
        uint8 _limit
    )
        external
        view
        override
        returns (address[] memory)
    {
        address[] storage _addresses = addressesByNft[_gameId][_nft];
        return AddressHelper.filterAddressByOffset(_addresses, _offset, _limit);
    }

    /**
     * returns at most 100 filters owned by msg.sender, filtered by gameId
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getMyfilters(
        uint256 _gameId,
        uint256 _offset,
        uint8 _limit
    )
        external
        view
        override
        returns (address[] memory)
    {
        address[] storage _addresses = filtersByOwner[msg.sender][_gameId];
        return AddressHelper.filterAddressByOffset(_addresses, _offset, _limit);
    }

    /**
     * returns at most 100 filters owned by msg.sender, filtered by gameid and nft
     * the result is sorted by id. in this prototype, it will not filter anything.
     */
    function getMyfiltersByNft(
        uint256 _gameId,
        address _nft,
        uint256 _offset,
        uint8 _limit
    )
        external
        view
        override
        returns (address[] memory)
    {
        address[] storage _addresses = filtersByNftAndOwner[msg.sender][_gameId][_nft];
        return AddressHelper.filterAddressByOffset(_addresses, _offset, _limit);
    }

    /**
     * Add a valid signer to verify signature
     * It is used to verify _signature in createFilter()
     * Permission: onlyOwner
     */
    function addSigner(address _signer) external override onlyOwner {
        require(_signer != address(0), "E-3e420c55b");
        signers[_signer] = true;
        emit SignerAdded(_signer);
    }

    /**
     * Remove a signer from the list of signers.
     * Permission: onlyOwner
     */
    function removeSigner(address _signer) external override onlyOwner {
        require(_signer != address(0), "E-3e4a0d55b");
        delete signers[_signer];
        emit SignerRemoved(_signer);
    }

    /**
     * Check signer of data belongs to our wallet address
     * Signer is the address which generated filter contract bytecode and signature
     */
    function verifySigner(
        address nft,
        uint256 chainId,
        bytes calldata bytecode,
        bytes calldata signature
    )
        private
        view
    {
        bytes32 payloadHash = keccak256(abi.encode(bytecode, chainId, nft));
        bytes32 messageHash = keccak256(bytes.concat("\x19Ethereum Signed Message:\n32", payloadHash));
        address actualSigner = ECDSA.recover(messageHash, signature);

        require(actualSigner != address(0), "E-3e454a637");
        require(signers[actualSigner] == true, "E-3e454a7e0");
    }

    /**
     * Deploy filter Contract
     * - Checks:
     *   - Contract is not an EOA (externally-owned account)
     *   - Contract is not yet deployed
     */
    function deployContract(
        uint256 _gameId,
        address _nftAddress,
        address _gameAddress,
        uint256 _chainId,
        bytes calldata _bytecode
    )
        private
        returns (address)
    {
        bytes memory filterBytecode = bytes.concat(_bytecode, abi.encode(_gameId, _nftAddress, _gameAddress));
        bytes32 bytecodeHash = keccak256(filterBytecode);

        // Precompute address of the contract to be deployed
        bytes32 salt = bytes32(_chainId);
        address computedAddress = Create2.computeAddress(salt, bytecodeHash);
        if (deployedAddresses[_gameId][_nftAddress][computedAddress]) {
            return computedAddress;
        }
        // Validate contract address to make sure it's not deployed yet
        require(Address.isContract(computedAddress) == false, "E-3e4f33444");

        return Create2.deploy(0, salt, filterBytecode);
    }
}
