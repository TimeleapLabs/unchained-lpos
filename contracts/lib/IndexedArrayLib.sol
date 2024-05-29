// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ArrayUtils.sol";

library IndexedArrayLib {
    using ArrayUtils for bytes32[];

    struct IndexedArray {
        bytes32[] array;
        mapping(bytes32 => uint256) indexMap;
    }

    error ElementAlreadyExists();
    error ElementDoesNotExist();

    /**
     * @dev Checks if an element exists in the array.
     * @param element The element to check.
     * @return True if the element exists, false otherwise.
     */
    function has(
        IndexedArray storage self,
        bytes32 element
    ) internal view returns (bool) {
        return (self.array.length > 0 &&
            self.indexMap[element] < self.array.length &&
            self.array[self.indexMap[element]] == element);
    }

    /**
     * @dev Adds an element to the array.
     * @param element The element to add.
     */
    function add(IndexedArray storage self, bytes32 element) internal {
        if (has(self, element)) {
            revert ElementAlreadyExists();
        }

        self.array.push(element);
        self.indexMap[element] = self.array.length - 1;
    }

    /**
     * @dev Removes an element from the array.
     * @param element The element to remove.
     */
    function remove(IndexedArray storage self, bytes32 element) internal {
        if (!has(self, element)) {
            revert ElementDoesNotExist();
        }

        uint256 index = self.indexMap[element];
        self.array.remove(index);

        delete self.indexMap[element];

        if (index < self.array.length) {
            self.indexMap[self.array[index]] = index;
        }
    }

    /**
     * @dev Gets an element from the array.
     * @param index The index of the element to get.
     * @return The element at the specified index.
     */
    function get(
        IndexedArray storage self,
        uint256 index
    ) internal view returns (bytes32) {
        if (index >= self.array.length) {
            revert ArrayUtils.IndexOutOfBounds(index, self.array.length);
        }

        return self.array[index];
    }

    /**
     * @dev Returns the slice of the array.
     * @param start The start index.
     * @param end The end index.
     * @return The slice of the array.
     */
    function slice(
        IndexedArray storage self,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return self.array.slice(start, end);
    }

    /**
     * @dev Returns the length of the array.
     * @return The length of the array.
     */
    function length(IndexedArray storage self) internal view returns (uint256) {
        return self.array.length;
    }

    /**
     * @dev Checks if the array is empty.
     * @return True if the array is empty, false otherwise.
     */
    function isEmpty(IndexedArray storage self) internal view returns (bool) {
        return self.array.length == 0;
    }

    /**
     * @dev Clears the array.
     */
    function clear(IndexedArray storage self) internal {
        for (uint256 i = 0; i < self.array.length; i++) {
            delete self.indexMap[self.array[i]];
        }

        delete self.array;
    }

    /**
     * @dev Returns all elements in the array.
     * @return All elements in the array.
     */
    function getAll(
        IndexedArray storage self
    ) internal view returns (bytes32[] memory) {
        return self.array;
    }
}
