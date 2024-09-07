// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "./Game.sol";

contract GameFactory {
    event GameCreated(address gameAddress);

    function createGame(bytes32 salt) external {
        address gameAddress;
        bytes memory bytecode = type(Game).creationCode;

        assembly {
            gameAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(gameAddress) {
                revert(0, 0)
            }
        }

        emit GameCreated(gameAddress);
    }

    function getGameAddress(bytes32 salt) external view returns (address) {
        bytes memory bytecode = type(Game).creationCode;
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }
}
