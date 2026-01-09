// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2} from "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "foundry-chainlink-toolkit/src/interfaces/vrf/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle Factory
 * @author Alejo Vilches
 * @notice This contracts creates a raffle for Drifters, a local shoe store in Buenos Aires
 * @dev It implements Chainlink VRFv2.5
 */

contract RaffleFactory is VRFConsumerBaseV2 {
    uint16 constant CONFIRMATIONS = 3;
    uint32 constant RANDOM_NUMBERS = 1;
    Raffle[] private raffleCollection;
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint32 immutable i_callbackGasLimit;
    address immutable i_admin;

    mapping(uint256 => uint256) public requestIdToRaffle;
    mapping(uint256 => mapping(address => bool)) public hasParticipated;

    error NotAdmin();
    error CreateRaffle_FinishBeforeStart();
    error DrawWinner_RaffleNotOpen();
    error DrawWinner_NotEnoughParticipants();
    error GetRaffle_InvalidRaffleId();
    error AddParticipant_AlreadyIn();
    error AddParticipant_InvalidRaffleId();
    error DrawWinner_InvalidRaffleId();
    error DrawWinner_NotFinishedYet();

    modifier OnlyAdmin() {
        if (msg.sender != i_admin) revert NotAdmin();
        _;
    }

    struct Raffle {
        address[] participants;
        uint256 startingTime;
        uint256 finishingTime;
        address winner;
        Status status;
        string metadataURI;
    }

    enum Status {
        OPEN,
        DRAW,
        CLOSED
    }

    event WinnerChosen(address indexed winner, uint256 indexed raffleId);
    event RaffleCreated(uint256 raffleId);
    event ParticipantAdded(
        address indexed participant,
        uint256 indexed raffleId
    );

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        address admin
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_admin = admin;
    }

    function createRaffle(
        uint256 start,
        uint256 finish,
        string calldata productInfo
    ) external OnlyAdmin {
        if (finish < start) revert CreateRaffle_FinishBeforeStart();
        raffleCollection.push(
            Raffle({
                participants: new address[](0),
                startingTime: start,
                finishingTime: finish,
                winner: address(0),
                status: Status.OPEN,
                metadataURI: productInfo
            })
        );
        emit RaffleCreated(raffleCollection.length - 1);
    }

    function getRaffle(uint256 raffleId) external view returns (Raffle memory) {
        if (raffleId >= raffleCollection.length)
            revert GetRaffle_InvalidRaffleId();
        return raffleCollection[raffleId];
    }

    function getRaffleCollectionLength() external view returns (uint256) {
        return raffleCollection.length;
    }

    function getAdmin() external view returns (address) {
        return i_admin;
    }

    function addParticipant(address participant, uint256 raffleId) external {
        if (raffleId >= raffleCollection.length)
            revert AddParticipant_InvalidRaffleId();
        if (hasParticipated[raffleId][participant])
            revert AddParticipant_AlreadyIn();
        raffleCollection[raffleId].participants.push(participant);
        hasParticipated[raffleId][participant] = true;
        emit ParticipantAdded(participant, raffleId);
    }

    //drawWinner ask for a random number to Chainlink. Is fulfillRandomWords who choses the winner
    function drawWinner(uint256 raffleId) external OnlyAdmin returns (uint256) {
        if (raffleId >= raffleCollection.length)
            revert DrawWinner_InvalidRaffleId();
        Raffle storage raffle = raffleCollection[raffleId];
        if (block.timestamp < raffle.finishingTime)
            revert DrawWinner_NotFinishedYet();
        if (raffle.status != Status.OPEN) revert DrawWinner_RaffleNotOpen();
        if (raffle.participants.length <= 0)
            revert DrawWinner_NotEnoughParticipants();

        raffleCollection[raffleId].status = Status.DRAW;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            CONFIRMATIONS,
            i_callbackGasLimit,
            RANDOM_NUMBERS
        );
        requestIdToRaffle[requestId] = raffleId;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 raffleId = requestIdToRaffle[requestId];
        uint256 winnerIndex = randomWords[0] %
            raffleCollection[raffleId].participants.length;
        raffleCollection[raffleId].winner = raffleCollection[raffleId]
            .participants[winnerIndex];
        raffleCollection[raffleId].status = Status.CLOSED;
        emit WinnerChosen(raffleCollection[raffleId].winner, raffleId);
    }
}
