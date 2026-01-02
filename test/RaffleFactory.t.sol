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

    function setUp() external {
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE
        );
        raffleFactory = new RaffleFactory(
            address(vrfCoordinatorMock),
            SUBSCRIPTION_ID,
            bytes32("keyHash"),
            CALLBACK_GASLIMIT,
            admin
        );
    }

    function testConstructorSetsAdmin() public {
        vm.prank(admin);
        assertEq(raffleFactory.getAdmin(), admin);
    }

    function testRaffleIsCreated() public {
        vm.prank(admin);
        raffleFactory.createRaffle(10000000, 10003400);
        RaffleFactory.Raffle memory raffle = raffleFactory.getRaffle(0);
        assertEq(raffle.startingTime, 10000000);
        assertEq(raffle.finishingTime, 10003400);
        assertEq(uint256(raffle.status), uint256(RaffleFactory.Status.OPEN));
        assertEq(raffle.participants.length, 0);
    }

    function testCreateRaffleRevertsIfFinishTimeIsShortThanStart() public {
        vm.prank(admin);
        vm.expectRevert(RaffleFactory.CreateRaffle_FinishBeforeStart.selector);
        raffleFactory.createRaffle(10003400, 10000000);
    }

    function testCreateRaffleRevertsIfCallerIsNotAdmin() public {
        vm.expectRevert(RaffleFactory.NotAdmin.selector);
        raffleFactory.createRaffle(10000000, 10003400);
    }
}
