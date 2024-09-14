// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

interface IGameFactory {
    /**
     * @notice Retrieves an address stored in the mapping.
     * @dev Converts the stored bytes32 value back to an address.
     * @param key The string key associated with the value.
     * @return The address associated with the key.
     */
    function getAddress(string memory key) external view returns (address);

    /**
     * @notice Retrieves a uint256 stored in the mapping.
     * @dev Converts the stored bytes32 value back to a uint256.
     * @param key The string key associated with the value.
     * @return The uint256 value associated with the key.
     */
    function getUint(string memory key) external view returns (uint256);

    /**
     * @notice Retrieves a boolean stored in the mapping.
     * @dev Converts the stored bytes32 value back to a boolean (true if 1, false if 0).
     * @param key The string key associated with the value.
     * @return The boolean value associated with the key.
     */
    function getBool(string memory key) external view returns (bool);

    /**
     * @notice Retrieves a bytes32 value stored in the mapping.
     * @dev Directly retrieves the bytes32 value associated with the key.
     * @param key The string key associated with the value.
     * @return The bytes32 value associated with the key.
     */
    function getBytes32(string memory key) external view returns (bytes32);
}
