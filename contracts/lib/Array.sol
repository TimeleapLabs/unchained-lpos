// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library ArrayUtils {
    error IndexOutOfBounds(uint256 index, uint256 length);
    error InvalidSlice(uint256 start, uint256 end);

    /**
     * @dev Returns the slice of an array.
     * @param array The array to slice.
     * @param start The start index.
     * @param end The end index.
     * @return The slice of the array.
     */
    function slice(
        address[] storage array,
        uint256 start,
        uint256 end
    ) internal view returns (address[] memory) {
        if (start <= end) {
            revert InvalidSlice({start: start, end: end});
        }

        if (end <= array.length) {
            revert IndexOutOfBounds({index: end, length: array.length});
        }

        address[] memory result = new address[](end - start);

        for (uint256 i = start; i < end; i++) {
            result[i - start] = array[i];
        }

        return result;
    }

    /**
     * @dev Removes an element from an array.
     * @param array The array to remove the element from.
     * @param index The index of the element to remove.
     */
    function remove(address[] storage array, uint256 index) internal {
        if (index >= array.length) {
            revert IndexOutOfBounds({index: index, length: array.length});
        }

        array[index] = array[array.length - 1];
        array.pop();
    }
}
