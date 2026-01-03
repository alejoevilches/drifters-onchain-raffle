// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffleFactory} from "../script/DeployRaffleFactory.s.sol";
import {RaffleFactory} from "../src/RaffleFactory.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleFactoryTest is Test {
    RaffleFactory raffleFactory;
    address admin = makeAddr("admin");
    uint256 private constant BALANCE = 10 ether;
    uint96 private constant BASE_FEE = 0.05 ether;
    uint96 private constant GAS_PRICE = 1e9;
    uint32 private constant CALLBACK_GASLIMIT = 500000;
    uint64 private constant SUBSCRIPTION_ID = 1;
    string constant METADATA_URI = "ipfs://test";
    VRFCoordinatorV2Mock vrfCoordinatorMock;

    function setUp() external {
        vrfCoordinatorMock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE);
        raffleFactory = new RaffleFactory(
            address(vrfCoordinatorMock),
            SUBSCRIPTION_ID,
            bytes32("keyHash"),
            CALLBACK_GASLIMIT,
            admin
        );

        uint64 subId = vrfCoordinatorMock.createSubscription();
        vrfCoordinatorMock.fundSubscription(subId, 10 ether);
        vrfCoordinatorMock.addConsumer(subId, address(raffleFactory));
    }

    function testConstructorSetsAdmin() public {
        vm.prank(admin);
        assertEq(raffleFactory.getAdmin(), admin);
    }

    function testRaffleIsCreated() public {
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit RaffleFactory.RaffleCreated(0);
        raffleFactory.createRaffle(10000000, 10003400, METADATA_URI);
        RaffleFactory.Raffle memory raffle = raffleFactory.getRaffle(0);
        assertEq(raffle.startingTime, 10000000);
        assertEq(raffle.finishingTime, 10003400);
        assertEq(uint256(raffle.status), uint256(RaffleFactory.Status.OPEN));
        assertEq(raffle.participants.length, 0);
    }

    function testCreateRaffleRevertsIfFinishTimeIsShortThanStart() public {
        vm.prank(admin);
        vm.expectRevert(RaffleFactory.CreateRaffle_FinishBeforeStart.selector);
        raffleFactory.createRaffle(10003400, 10000000, METADATA_URI);
    }

    function testCreateRaffleRevertsIfCallerIsNotAdmin() public {
        vm.expectRevert(RaffleFactory.NotAdmin.selector);
        raffleFactory.createRaffle(10000000, 10003400, METADATA_URI);
    }

    function testGetRaffleRevertsIfRaffleIdIsInvalid() public {
        vm.expectRevert(RaffleFactory.GetRaffle_InvalidRaffleId.selector);
        raffleFactory.getRaffle(912);
    }

    function testParticipantIsAdded() public {
        address user = makeAddr("user");
        vm.prank(admin);
        raffleFactory.createRaffle(10000000, 10003400, METADATA_URI);
        vm.expectEmit(true, true, false, false);
        emit RaffleFactory.ParticipantAdded(user, 0);
        raffleFactory.addParticipant(user, 0);
        RaffleFactory.Raffle memory raffle = raffleFactory.getRaffle(0);
        assertEq(raffle.participants.length, 1);
    }

    function testAddParticipantRevertsIfRaffleIdIsInvalid() public {
        address user = makeAddr("user");
        vm.expectRevert(RaffleFactory.AddParticipant_InvalidRaffleId.selector);
        raffleFactory.addParticipant(user, 0);
    }

    function testAddParticipantRevertsIfParticipantIsAlreadyAdded() public {
        address user = makeAddr("user");
        vm.prank(admin);
        raffleFactory.createRaffle(10000000, 10003400, METADATA_URI);
        raffleFactory.addParticipant(user, 0);
        vm.expectRevert(RaffleFactory.AddParticipant_AlreadyIn.selector);
        raffleFactory.addParticipant(user, 0);
    }

    function testDrawWinnerRequestsRandomNumber() public {
        address user = makeAddr("user");
        vm.startPrank(admin);
        raffleFactory.createRaffle(10000000, 10000001, METADATA_URI);
        vm.warp(10000001 + 1);
        raffleFactory.addParticipant(user, 0);
        uint256 requestId = raffleFactory.drawWinner(0);
        vm.stopPrank();
        RaffleFactory.Raffle memory raffle = raffleFactory.getRaffle(0);
        assertEq(uint256(raffle.status), uint256(RaffleFactory.Status.DRAW));
        assertGt(requestId, 0);
        assertEq(raffleFactory.requestIdToRaffle(requestId), 0);
        assertEq(raffle.winner, address(0));
    }

    function testDrawWinnerRevertsIfRaffleIdIsInvalid() public {
        vm.prank(admin);
        vm.expectRevert(RaffleFactory.DrawWinner_InvalidRaffleId.selector);
        raffleFactory.drawWinner(0);
    }

    function testDrawWinnerRevertsIfRaffleIsThereAreNotEnoughParticipants()
        public
    {
        vm.startPrank(admin);
        raffleFactory.createRaffle(10000000, 10000001, METADATA_URI);
        vm.warp(10000001 + 1);
        vm.expectRevert(
            RaffleFactory.DrawWinner_NotEnoughParticipants.selector
        );
        raffleFactory.drawWinner(0);
        vm.stopPrank();
    }

    function testDrawWinnerRevertsIfRaffleIsNotFinishedYet() public {
        address user = makeAddr("user");
        vm.startPrank(admin);
        raffleFactory.createRaffle(10000000, 20000000, METADATA_URI);
        raffleFactory.addParticipant(user, 0);
        vm.expectRevert(RaffleFactory.DrawWinner_NotFinishedYet.selector);
        raffleFactory.drawWinner(0);
    }

    function testDrawWinnerRevertsIfRaffleStatusIsNotOpen() public {
        address user = makeAddr("user");
        vm.startPrank(admin);
        raffleFactory.createRaffle(10000000, 10000001, METADATA_URI);
        vm.warp(10000001 + 1);
        raffleFactory.addParticipant(user, 0);
        raffleFactory.drawWinner(0);
        vm.expectRevert(RaffleFactory.DrawWinner_RaffleNotOpen.selector);
        raffleFactory.drawWinner(0);
        vm.stopPrank();
    }

    function testDrawWinnerRevertsIfCalledByNotAdmin() public {
        address user = makeAddr("user");
        vm.prank(user);
        vm.expectRevert(RaffleFactory.NotAdmin.selector);
        raffleFactory.drawWinner(0);
    }

    function testFulfillRandomWordsSelectsWinner() public {
        address user = makeAddr("user");
        vm.startPrank(admin);
        raffleFactory.createRaffle(10000000, 20000000, METADATA_URI);
        raffleFactory.addParticipant(user, 0);
        vm.warp(20000000 + 1);
        uint256 requestId = raffleFactory.drawWinner(0);
        vm.stopPrank();
        vm.expectEmit(true, true, false, false);
        emit RaffleFactory.WinnerChosen(user, 0);
        vrfCoordinatorMock.fulfillRandomWords(
            requestId,
            address(raffleFactory)
        );
        RaffleFactory.Raffle memory raffle = raffleFactory.getRaffle(0);
        assertTrue(raffle.winner == user);
        assertEq(uint256(raffle.status), uint256(RaffleFactory.Status.CLOSED));
    }
}
