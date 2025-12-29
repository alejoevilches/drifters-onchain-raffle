// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2} from "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "foundry-chainlink-toolkit/src/interfaces/vrf/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle Factory
 * @author ...
 * @notice This contracts creates a raffle for Drifters
 * @dev It implements Chainlink VRFv2.5
 */

contract RaffleFactory is VRFConsumerBaseV2 {
    Raffle[] private raffleCollection;
    VRFCoordinatorV2Interface i_vrfCoordinator;
    uint64 i_subscriptionId;
    bytes32 i_keyHash;
    uint32 i_callbackGasLimit;

    error CreateRaffle_FinishBeforeStart();
    error DrawWinner_RaffleNotOpen();

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
        if (raffleCollection[raffleId].status == Status.OPEN)
            revert DrawWinner_RaffleNotOpen();

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, // gas lane / keyHash
            i_subscriptionId, // tu subscripción
            3, // request confirmations
            i_callbackGasLimit, // gas para el callback
            1 // 👈 numWords = 1
        );
    }
}
