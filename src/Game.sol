// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "./UserBets.sol";

contract Game {
    using Math for uint256;

    struct GameStatus {
        address resolver;
        ERC20 reward;
        uint40 expectedEnd;
        bool resolved;
        bytes32 winningOption;
    }

    GameStatus public status;
    UserBets public bets;
    bytes32[] private _options;

    event OptionPicked(address indexed player, bytes32 option, uint amount);
    event GameResolved(bytes32 winningOption);
    event RewardClaimed(address indexed player, uint amount);

    error AlreadyResolved();
    error InvalidOption(bytes32 option);
    error NoReward();
    error AlreadyFinished();
    error NotFinished();
    error NotResolver();

    constructor(
        address resolver,
        ERC20 token,
        uint40 expectedEnd,
        bytes32[] memory optionNames
    ) {
        // Deploy the ERC1155 token contract for position tokens
        bets = new UserBets();

        // Initialize the game status
        status.resolver = resolver;
        status.reward = token;
        status.expectedEnd = expectedEnd;
        status.resolved = false;

        _options = optionNames;
    }

    function addLiquidity(uint amount) public {
        if (block.timestamp > status.expectedEnd) revert AlreadyFinished(); // Prevent betting after the game ends

        // Transfer the ERC20 tokens from the player to the game contract
        status.reward.transferFrom(msg.sender, address(this), amount);

        uint optionCount = _options.length;
        uint mintEach = amount / optionCount;

        for(uint8 i = 0; i < optionCount; i++) {
            bets.mint(msg.sender, _options[i], mintEach);
            emit OptionPicked(msg.sender, _options[i], amount);
        }
    }

    // Function for players to pick an option and stake tokens
    function pickOption(bytes32 option, uint amount) external {
        if (!_hasOption(option)) revert InvalidOption(option);
        if (block.timestamp > status.expectedEnd) revert AlreadyFinished(); // Prevent betting after the game ends

        // Transfer the ERC20 tokens from the player to the game contract
        status.reward.transferFrom(msg.sender, address(this), amount);

        // Mint ERC1155 position tokens (for the selected option) to the player
        bets.mint(msg.sender, option, amount);

        emit OptionPicked(msg.sender, option, amount);
    }

    // Function for the resolver to resolve the game by passing the winning option as a string
    function resolveGame(bytes32 winningOption) external {
        if (msg.sender != status.resolver) revert NotResolver();
        if (status.resolved) revert AlreadyResolved();
        if (!_hasOption(winningOption)) revert InvalidOption(winningOption);

        status.resolved = true;
        status.winningOption = winningOption;

        emit GameResolved(winningOption);
    }

    // Function for players to claim rewards after the game is resolved
    function claimReward() external {
        if (!status.resolved) revert NotFinished();
        uint playerBetAmount = bets.balanceOf(msg.sender, status.winningOption);
        if (playerBetAmount == 0) revert NoReward();

        // Calculate the player's reward based on their stake and the total staked in the winning option
        uint prize = totalStaked();
        uint winningOptionBets = getBetsByOption(status.winningOption);
        uint reward = playerBetAmount.mulDiv(prize, winningOptionBets, Math.Rounding.Floor);

        // Burns user bets
        bets.burn(msg.sender, status.winningOption, reward);
        // Unlocks the rewards
        status.reward.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Helper function to check if the game has ended
    function hasGameEnded() public view returns (bool) {
        return block.timestamp > status.expectedEnd;
    }

    // Helper function to get the total pool of tokens staked in the game
    function totalStaked() public view returns (uint) {
        return status.reward.balanceOf(address(this));
    }

    function getBetsByOption(bytes32 option) public view returns (uint) {
        return bets.totalSupply(option);
    }

    function _hasOption(bytes32 option) internal view returns (bool) {
        uint optionCount = _options.length;
        for(uint8 i = 0; i < optionCount; i++) {
            if (option == _options[i]) {
                return true;
            }
        }
        return false;
    }
}
