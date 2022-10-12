// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library MathHelper {

    /**
    * Returns the largest of two signed numbers
    */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
    * Returns the smallest of two signed numbers
    */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * Returns the smallest of two numbers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * Returns the absolute unsigned value of a signed value
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

    /**
    * Returns the square root if a number. If the number is not a perfect square, the value is rounded down
    */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 is smaller than the square root of the target
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a)<=a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // -> `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // -> `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit
        uint256 result = 1 << (log2(a >> 1));

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * Returns the log in base 2, rounded down, of a positive value
     * Returns 0 if given 0
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;

        unchecked {
             if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

}
