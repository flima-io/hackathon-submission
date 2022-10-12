// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IFixedStakingPool.sol";
import "./IFixedStakingNote.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FixedStakingPool is IFixedStakingPool {
    address flima;
    address note;

    using SafeERC20 for IERC20;

    /**
     * @inheritdoc IFixedStakingPool
     */
    function deposit(StakingType _stakingType, uint256 _amount)
        external
        override
    {
        // Checks
        require(_amount > 0);
        // uint256 stakeUntil = _calculateStakeEnd(_stakingType);
        // Effects
        FixedStaking memory staking = FixedStaking(
            _stakingType,
            1000,
            uint64(block.timestamp),
            uint64(block.timestamp),
            _amount,
            msg.sender
        );
        // Interactions
        IERC20(flima).safeTransferFrom(msg.sender, address(this), _amount);
        IFixedStakingNote(note).mint(staking);
    }

    function _calculateStakeEnd(StakingType _stakingType)
        private
        view
        returns (uint256)
    {
        uint256 year;
        if (_stakingType == StakingType.oneYear) {
            year = 1;
        } else if (_stakingType == StakingType.twoYears) {
            year = 2;
        } else if (_stakingType == StakingType.fourYears) {
            year = 4;
        } else {
            require(false, "");
        }
        return block.timestamp + (year * 365 days);
    }

    function claimReward(uint256 tokenId) external override {}

    function withdraw(uint256 tokenId) external override {
        IFixedStakingNote _note = IFixedStakingNote(note);
        require(_note.canWithdraw(tokenId), "");
        _note.burn(tokenId);
    }

    function getClaimable(uint256 _id)
        external
        view
        override
        returns (uint256)
    {}

    function getStakedAmount(uint256 _id)
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
