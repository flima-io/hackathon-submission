// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../filter/IFilter.sol";

contract MockFilter is IFilter {
    bool result = true;

    function setMockResult(bool b) external {
        result = b;
    }

    function filter(uint256 _tokenId) external view override returns (bool) {
        return result;
    }
}
