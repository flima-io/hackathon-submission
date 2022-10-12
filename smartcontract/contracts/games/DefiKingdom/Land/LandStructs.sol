// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LandMeta {
    uint256 landId;
    string name;
    address owner;
    uint256 region;
    uint8 level;
    uint256 steward;
    uint64 score;
}
