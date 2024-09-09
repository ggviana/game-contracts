// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract UserBets is ERC1155 {
    address public game;

    mapping(bytes32 => uint256) private _totalSupply;

    constructor() ERC1155("") {
        game = msg.sender; // The game contract becomes the minter
    }

    function getTokenId(bytes32 option) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(option)));
    }

    function totalSupply(bytes32 option) public view virtual returns (uint256) {
        return _totalSupply[option];
    }

    function balanceOf(address account, bytes32 option) public view virtual returns (uint256) {
        uint tokenId = getTokenId(option);
        return super.balanceOf(account, tokenId);
    }

    // Only the Game contract can mint tokens
    function mint(
        address to,
        bytes32 option,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can mint");
        uint tokenId = getTokenId(option);
        _totalSupply[option] += amount;
        _mint(to, tokenId, amount, "");
    }

    // Only the Game contract can burn tokens
    function burn(
        address from,
        bytes32 option,
        uint256 amount
    ) external {
        require(msg.sender == game, "Only game can burn");
        uint tokenId = getTokenId(option);
        _totalSupply[option] -= amount;
        _burn(from, tokenId, amount);
    }
}
