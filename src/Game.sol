// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract GamePositionToken1155 is ERC1155 {
    address public game;

    constructor() ERC1155("") {
        game = msg.sender; // The game contract becomes the minter
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

contract Game {
    struct PlayerBet {
        string optionName; // String option name
        uint amount;
    }

    struct GameStatus {
        address resolver;
        ERC20 token;
        uint40 expectedEnd;
        bool resolved;
        string winningOption;
        mapping(string => uint) optionTotalStakes; // Total stake for each option (by string)
    }

    GameStatus public status;
    mapping(address => PlayerBet) public playerBets;
    mapping(address => bool) public hasClaimedReward;
    GamePositionToken1155 public positionTokenContract;
    string[] public options; // List of option names (e.g., ["yes", "no"])

    event OptionPicked(address indexed player, string optionName, uint amount);
    event GameResolved(string winningOption);
    event RewardClaimed(address indexed player, uint amount);

    error GameOptionDontExist();
    error GameAlreadyResolved();
    error InvalidOption();
    error NoBetPlaced();
    error RewardAlreadyClaimed();
    error GameNotFinished();

    constructor(
        address resolver,
        ERC20 token,
        uint40 expectedEnd,
        string[] memory optionNames
    ) {
        // Deploy the ERC1155 token contract for position tokens
        positionTokenContract = new GamePositionToken1155();

        // Initialize the game status
        status.resolver = resolver;
        status.token = token;
        status.expectedEnd = expectedEnd;
        status.resolved = false;

        // Set up options based on the provided array of strings
        for (uint i = 0; i < optionNames.length; i++) {
            options.push(optionNames[i]); // Store the option name
            status.optionTotalStakes[optionNames[i]] = 0; // Initialize total stakes for this option to 0
        }
    }

    // Function for players to pick an option and stake tokens
    function pickOption(string memory optionName, uint amount) external {
        if (bytes(optionName).length == 0 || status.optionTotalStakes[optionName] == 0) revert GameOptionDontExist();
        if (block.timestamp > status.expectedEnd) revert GameNotFinished(); // Prevent betting after the game ends

        // Transfer the ERC20 tokens from the player to the game contract
        status.token.transferFrom(msg.sender, address(this), amount);

        // Mint ERC1155 position tokens (for the selected option) to the player
        positionTokenContract.mint(msg.sender, optionName, amount);

        // Update the player's bet and the total staked for the selected option
        playerBets[msg.sender] = PlayerBet(optionName, amount);
        status.optionTotalStakes[optionName] += amount;

        emit OptionPicked(msg.sender, optionName, amount);
    }

    // Function for the resolver to resolve the game by passing the winning option as a string
    function resolveGame(string memory winningOption) external {
        if (msg.sender != status.resolver) revert InvalidOption();

        if (status.resolved) revert GameAlreadyResolved();
        if (bytes(winningOption).length == 0 || status.optionTotalStakes[winningOption] == 0) revert InvalidOption();

        status.resolved = true;
        status.winningOption = winningOption;

        // Burn losing tokens for all players
        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) != keccak256(bytes(winningOption))) {
                positionTokenContract.burn(address(this), options[i], status.optionTotalStakes[options[i]]);
            }
        }

        emit GameResolved(winningOption);
    }

    // Function for players to claim rewards after the game is resolved
    function claimReward() external {
        if (!status.resolved) revert GameNotFinished();
        PlayerBet storage playerBet = playerBets[msg.sender];
        if (playerBet.amount == 0) revert NoBetPlaced();
        if (hasClaimedReward[msg.sender]) revert RewardAlreadyClaimed();

        // Check if the player's bet was on the winning option
        if (keccak256(bytes(playerBet.optionName)) != keccak256(bytes(status.winningOption))) {
            hasClaimedReward[msg.sender] = true;
            emit RewardClaimed(msg.sender, 0);
            return; // Player bet on the wrong option, no reward
        }

        // Calculate the player's reward based on their stake and the total staked in the winning option
        uint reward = (playerBet.amount * status.token.balanceOf(address(this))) / status.optionTotalStakes[status.winningOption];
        hasClaimedReward[msg.sender] = true;
        status.token.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Helper function to check if the game has ended
    function hasGameEnded() public view returns (bool) {
        return block.timestamp > status.expectedEnd;
    }

    // Helper function to get the total pool of tokens staked in the game
    function getTotalPool() public view returns (uint) {
        return status.token.balanceOf(address(this));
    }

    // Function to retrieve all option names
    function getOptionNames() external view returns (string[] memory) {
        return options;
    }
}
