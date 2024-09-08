// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract GamePositions is ERC1155 {
    address public game;

    constructor() ERC1155("") {
        game = msg.sender; // The game contract becomes the minter
    }

    function getTokenId(string memory option) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(option)));
    }

    // Only the Game contract can mint tokens
    function mint(
        address to,
        string memory option,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can mint");
        uint tokenId = getTokenId(option);
        _mint(to, tokenId, amount, "");
    }

    // Only the Game contract can burn tokens
    function burn(
        address from,
        string memory option,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can burn");
        uint tokenId = getTokenId(option);
        _burn(from, tokenId, amount);
    }
}
