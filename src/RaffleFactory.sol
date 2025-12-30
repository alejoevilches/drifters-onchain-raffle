// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2} from "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "foundry-chainlink-toolkit/src/interfaces/vrf/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle Factory
 * @author Alejo Vilches
 * @notice This contracts creates a raffle for Drifters
 * @dev It implements Chainlink VRFv2.5
 */

contract RaffleFactory is VRFConsumerBaseV2 {
    Raffle[] private raffleCollection;
    VRFCoordinatorV2Interface i_vrfCoordinator;
    uint64 i_subscriptionId;
    bytes32 i_keyHash;
    uint32 i_callbackGasLimit;

    mapping(uint256 => uint256) requestIdToRaffle;

    error CreateRaffle_FinishBeforeStart();
    error DrawWinner_RaffleNotOpen();
    error DrawWinner_NotEnoughParticipants();

    struct Raffle {
        address[] participants;
        uint256 startingTime;
        uint256 finishingTime;
        address winner;
        Status status;
    }

    enum Status {
        OPEN,
        DRAW,
        CLOSED
    }

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function createRaffle(uint256 start, uint256 finish) external {
        if (finish < start) revert CreateRaffle_FinishBeforeStart();
        raffleCollection.push(
            Raffle({
                participants: new address[](0),
                startingTime: start,
                finishingTime: finish,
                winner: address(0),
                status: Status.OPEN
            })
        );
    }

    function getRaffleCollection() external view returns (Raffle[] memory) {
        return raffleCollection;
    }

    function addParticipant(address participant, uint256 raffleId) external {
        raffleCollection[raffleId].participants.push(participant);
    }

    function drawWinner(uint256 raffleId) external {
        Raffle memory raffle = raffleCollection[raffleId];
        if (raffle.status != Status.OPEN) revert DrawWinner_RaffleNotOpen();

        if (raffle.participants.length <= 0)
            revert DrawWinner_NotEnoughParticipants();

        raffleCollection[raffleId].status = Status.DRAW;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            3,
            i_callbackGasLimit,
            1
        );
        requestIdToRaffle[requestId] = raffleId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal view override {
        uint256 raffleId = requestIdToRaffle[requestId];
        Raffle memory raffle = raffleCollection[raffleId];
        uint256 winnerIndex = randomWords[0] % raffle.participants.length;
        raffle.winner = raffle.participants[winnerIndex];
        raffle.status = Status.CLOSED;
    }
}
