// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

/**
 * @title Storage Contract
 * @notice This contract allows storing and retrieving various types of data
 * (address, uint256, bool, bytes32) in a bytes32 mapping.
 */
contract Storage {
    /**
     * @notice Public mapping to store data in bytes32 format.
     * @dev The mapping allows storage and retrieval of data using string keys.
     */
    mapping(string => bytes32) public data;

    /**
     * @notice Stores an address in the mapping.
     * @dev Converts the address to a bytes32 format and stores it in the data mapping.
     * @param key The string key associated with the value.
     * @param addr The address to be stored.
     */
    function _setAddress(string memory key, address addr) public {
        data[key] = bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice Retrieves an address stored in the mapping.
     * @dev Converts the stored bytes32 value back to an address.
     * @param key The string key associated with the value.
     * @return The address associated with the key.
     */
    function getAddress(string memory key) public view returns (address) {
        return address(uint160(uint256(data[key])));
    }

    /**
     * @notice Stores a uint256 in the mapping.
     * @dev Converts the uint256 to a bytes32 format and stores it in the data mapping.
     * @param key The string key associated with the value.
     * @param value The uint256 value to be stored.
     */
    function _setUint(string memory key, uint256 value) public {
        data[key] = bytes32(value);
    }

    /**
     * @notice Retrieves a uint256 stored in the mapping.
     * @dev Converts the stored bytes32 value back to a uint256.
     * @param key The string key associated with the value.
     * @return The uint256 value associated with the key.
     */
    function getUint(string memory key) public view returns (uint256) {
        return uint256(data[key]);
    }

    /**
     * @notice Stores a boolean in the mapping.
     * @dev Converts the bool to a bytes32 format (1 for true, 0 for false) and stores it in the data mapping.
     * @param key The string key associated with the value.
     * @param value The boolean value to be stored.
     */
    function _setBool(string memory key, bool value) public {
        data[key] = value ? bytes32(uint256(1)) : bytes32(uint256(0));
    }

    /**
     * @notice Retrieves a boolean stored in the mapping.
     * @dev Converts the stored bytes32 value back to a boolean (true if 1, false if 0).
     * @param key The string key associated with the value.
     * @return The boolean value associated with the key.
     */
    function getBool(string memory key) public view returns (bool) {
        return uint256(data[key]) == 1;
    }

    /**
     * @notice Stores a bytes32 value in the mapping.
     * @dev Directly stores the bytes32 value in the data mapping.
     * @param key The string key associated with the value.
     * @param value The bytes32 value to be stored.
     */
    function _setBytes32(string memory key, bytes32 value) internal {
        data[key] = value;
    }

    /**
     * @notice Retrieves a bytes32 value stored in the mapping.
     * @dev Directly retrieves the bytes32 value associated with the key.
     * @param key The string key associated with the value.
     * @return The bytes32 value associated with the key.
     */
    function getBytes32(string memory key) public view returns (bytes32) {
        return data[key];
    }
}
