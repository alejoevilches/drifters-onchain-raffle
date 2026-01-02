//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {RaffleFactory} from "src/RaffleFactory.sol";

contract DeployRaffleFactory is Script {
    function run() public returns (RaffleFactory) {
        vm.startBroadcast();
        RaffleFactory raffleFactory = new RaffleFactory(
            vm.envAddress("VRF_COORDINATOR"),
            uint64(vm.envUint("SUBSCRIPTION_ID")),
            vm.envBytes32("VRF_KEYHASH"),
            500000,
            msg.sender
        );
        vm.stopBroadcast();
        return raffleFactory;
    }
}
