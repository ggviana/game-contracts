// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract GamePositions is ERC1155 {
    address public game;

    constructor() ERC1155("") {
        game = msg.sender; // The game contract becomes the minter
    }

    function getTokenId(string memory id) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(id))); // Generate unique ID based on string
    }

    // Only the Game contract can mint tokens
    function mint(
        address to,
        string memory id,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can mint");
        uint tokenId = uint(keccak256(abi.encodePacked(id))); // Generate unique ID based on string
        _mint(to, tokenId, amount, "");
    }

    // Only the Game contract can burn tokens
    function burn(
        address from,
        string memory id,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can burn");
        uint tokenId = uint(keccak256(abi.encodePacked(id))); // Generate unique ID based on string
        _burn(from, tokenId, amount);
    }
}
