// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library AddressHelper {
    function filterAddressByOffset(
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
}
