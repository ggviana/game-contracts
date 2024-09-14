// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IUserBets is IERC1155 {
    /**
     * @notice Returns the token ID corresponding to the given option.
     * @param option The bytes32 option to generate a token ID for.
     * @return The uint token ID generated from the option.
     */
    function getTokenId(bytes32 option) external pure returns (uint256);

    /**
     * @notice Returns the total supply of tokens for the given option.
     * @param option The bytes32 option to get the total supply for.
     * @return The total supply of tokens for the given option.
     */
    function totalSupply(bytes32 option) external view returns (uint256);

    /**
     * @notice Returns the balance of a specific account for the given option.
     * @param account The address of the account to check the balance of.
     * @param option The bytes32 option to check the balance for.
     * @return The balance of the account for the specified option.
     */
    function balanceOf(address account, bytes32 option) external view returns (uint256);

    /**
     * @notice Mints tokens of a specific option for a given account.
     * @param to The address to mint the tokens to.
     * @param option The bytes32 option representing the type of token.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, bytes32 option, uint256 amount) external;

    /**
     * @notice Burns tokens of a specific option from a given account.
     * @param from The address from which the tokens will be burned.
     * @param option The bytes32 option representing the type of token.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, bytes32 option, uint256 amount) external;

    /**
     * @notice Returns the address of the game contract.
     * @return The address of the game.
     */
    function game() external view returns (address);
}
