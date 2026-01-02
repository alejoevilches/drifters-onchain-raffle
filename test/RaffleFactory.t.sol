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
}
