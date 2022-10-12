// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Pet {
    uint256 id;
    uint8 originId;
    string name;
    uint8 season;
    uint8 eggType;
    uint8 rarity;
    uint8 element;
    uint8 bonusCount;
    uint8 profBonus;
    uint8 profBonusScalar;
    uint8 craftBonus;
    uint8 craftBonusScalar;
    uint8 combatBonus;
    uint8 combatBonusScalar;
    uint16 appearance;
    uint8 background;
    uint8 shiny;
    uint64 hungryAt;
    uint64 equippableAt;
    uint256 equippedTo;
}
