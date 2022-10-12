// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Staking {
    uint64 lastClaimedAt;
    uint256 amount;
}

interface IStakingPool {
    // mapping(address => Staking) balance;

    function deposit(uint256 _amount) external;

    function claimReward() external;

    function withdraw() external;

    function getClaimable(address _owner) external view returns (uint256);

    function getStakedAmount(address _owner) external view returns (uint256);
}
