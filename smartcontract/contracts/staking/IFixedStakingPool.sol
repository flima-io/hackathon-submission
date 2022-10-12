// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum StakingType {
    oneYear,
    twoYears,
    fourYears
}

struct FixedStaking {
    StakingType stakingType;
    uint16 rate;
    uint64 lastClaimedAt;
    uint64 depositedAt;
    uint256 amount;
    address owner;
}

interface IFixedStakingPool {
    /**
     * @dev Deposit token to start new fixed duration staking.
     * @param _stakingType Duration of the staking. 1, 2 and 4 years.
     * @param _amount Amount of $FLIMA to stake
     * - Checks
     *   - Nothing. Anyone can call it.
     * - Effects
     *   - A FixedStaking entry is created and an NFT that contains all the information is sent to the user.
     */
    function deposit(StakingType _stakingType, uint256 _amount) external;

    function claimReward(uint256 tokenId) external;

    function withdraw(uint256 tokenId) external;

    function getClaimable(uint256 _id) external view returns (uint256);

    function getStakedAmount(uint256 _id) external view returns (uint256);

    function canWithdraw(uint256 _id) external view returns (bool);

    function getUnlockDate(uint256 _id) external view returns (uint256);
}
