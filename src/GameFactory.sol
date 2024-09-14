// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Game} from "./Game.sol";
import {Storage} from "./Storage.sol";
import {OrderBook} from "./OrderBook.sol";

contract GameFactory is Ownable, Storage {
    UserBets public bets;
    OrderBook public orderbook;

    event GameCreated(address gameAddress);

    constructor(address money) Ownable(msg.sender) {
        bets = new UserBets();
        orderbook = new OrderBook();
        _setAddress("contracts.Money", money);
    }

    function setMoney(address money) public onlyOwner {
        _setAddress("contracts.Money", money);
    }

    function createGame(bytes32 salt) external onlyOwner {
        address gameAddress;
        bytes memory bytecode = type(Game).creationCode;

        assembly {
            gameAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(gameAddress) { revert(0, 0) }
        }

        emit GameCreated(gameAddress);
    }

    function getGameAddress(bytes32 salt) external view returns (address) {
        bytes memory bytecode = type(Game).creationCode;
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}
