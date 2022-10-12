// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ArrayHelper {
    function getLimit(
        uint256 length,
        uint256 offset,
        uint8 limit
    ) public pure returns (uint256) {

        if (length == 0) {
            return 0;
        }

        if (offset >= length) {
            return 0;
        }

        if (limit == 0) {
            limit = 10;
        }
        if (limit > 100) {
            limit = 100;
        }
        if (length < offset + limit) {
            limit = uint8(length - offset);
        }
        return limit;
    }
}
