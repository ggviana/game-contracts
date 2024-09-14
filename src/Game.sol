// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Math} from "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {UserBets} from "./UserBets.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

contract Game {
    using Math for uint256;

    struct GameStatus {
        address resolver;
        uint40 expectedEnd;
        bool resolved;
        bytes32 winningOption;
    }

    GameStatus public status;
    IGameFactory public factory;
    bytes32[] private _options;

    event OptionPicked(address indexed player, bytes32 option, uint256 amount);
    event GameResolved(bytes32 winningOption);
    event RewardClaimed(address indexed player, uint256 amount);

    error AlreadyResolved();
    error InvalidOption(bytes32 option);
    error NoReward();
    error AlreadyFinished();
    error NotFinished();
    error NotResolver();

    constructor(address resolver, uint40 expectedEnd, bytes32[] memory options) {
        factory = IGameFactory(msg.sender);

        // Initialize the game status
        status.resolver = resolver;
        status.expectedEnd = expectedEnd;
        status.resolved = false;

        _options = options;
    }

    function addLiquidity(uint256 amount) public {
        if (block.timestamp > status.expectedEnd) revert AlreadyFinished(); // Prevent betting after the game ends
        IUserBets bets = IUserBets(factory.getAddress("contracts.UserBets"));
        IERC20 money = IERC20(factory.getAddress("contracts.Money"));

        // Transfer the ERC20 tokens from the player to the game contract
        money.transferFrom(msg.sender, address(this), amount);

        uint256 optionCount = _options.length;
        uint256 mintEach = amount / optionCount;

        for (uint8 i = 0; i < optionCount; i++) {
            bets.mint(msg.sender, _options[i], mintEach);
            emit OptionPicked(msg.sender, _options[i], amount);
        }
    }

    // Function for players to pick an option and stake tokens
    function pickOption(bytes32 option, uint256 amount) external {
        if (!_hasOption(option)) revert InvalidOption(option);
        if (block.timestamp > status.expectedEnd) revert AlreadyFinished(); // Prevent betting after the game ends
        IUserBets bets = IUserBets(factory.getAddress("contracts.UserBets"));
        IERC20 money = IERC20(factory.getAddress("contracts.Money"));

        // Transfer the ERC20 tokens from the player to the game contract
        money.transferFrom(msg.sender, address(this), amount);

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
        IUserBets bets = IUserBets(factory.getAddress("contracts.UserBets"));
        IERC20 money = IERC20(factory.getAddress("contracts.Money"));
        uint256 playerBetAmount = bets.balanceOf(msg.sender, status.winningOption);
        if (playerBetAmount == 0) revert NoReward();

        // Calculate the player's reward based on their stake and the total staked in the winning option
        uint256 prize = totalStaked();
        uint256 winningOptionBets = getBetsByOption(status.winningOption);
        uint256 reward = playerBetAmount.mulDiv(prize, winningOptionBets, Math.Rounding.Floor);

        // Burns user bets
        bets.burn(msg.sender, status.winningOption, reward);
        // Unlocks the rewards
        money.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Helper function to check if the game has ended
    function hasGameEnded() public view returns (bool) {
        return block.timestamp > status.expectedEnd;
    }

    // Helper function to get the total pool of tokens staked in the game
    function totalStaked() public view returns (uint256) {
        IERC20 money = IERC20(factory.getAddress("contracts.Money"));
        return money.balanceOf(address(this));
    }

    function getBetsByOption(bytes32 option) public view returns (uint256) {
        IUserBets bets = IUserBets(factory.getAddress("contracts.UserBets"));
        return bets.totalSupply(option);
    }

    function _hasOption(bytes32 option) internal view returns (bool) {
        uint256 optionCount = _options.length;
        for (uint8 i = 0; i < optionCount; i++) {
            if (option == _options[i]) {
                return true;
            }
        }
        return false;
    }
}
