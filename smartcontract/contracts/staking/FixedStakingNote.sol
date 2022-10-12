// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IFixedStakingNote.sol";

contract FixedStakingNote is IFixedStakingNote {
    address _stakingPool;

    uint256 currentTokenId = 0;

    mapping(uint256 => FixedStaking) data;

    constructor() ERC721("FixedStakingNote", "") {}

    modifier onlyPool() {
        // TODO
        _;
    }

    function mint(FixedStaking calldata _fixedStaking)
        external
        override
        onlyPool
    {
        currentTokenId += 1;
        _mint(_fixedStaking.owner, currentTokenId);
    }

    function burn(uint256 tokenId) external override onlyPool {
        _burn(tokenId);
    }

    function getClaimable(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {}

    function getStaking(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {}

    function canWithdraw(uint256 _id) external view override returns (bool) {}

    function getUnlockDate(uint256 _id)
        external
        view
        override
        returns (uint256)
    {}
}
