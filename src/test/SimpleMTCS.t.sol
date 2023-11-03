// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {console} from "forge-std/console.sol";
import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";

import {Utils} from "./utils/Utils.sol";
import {SimpleMTCS} from "../SimpleMTCS.sol";

contract BaseSetup is SimpleMTCS, Test {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;
    address internal carol;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(3);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        carol = users[2];
        vm.label(carol, "Carol");
    }
}

contract Setup1 is BaseSetup {
    function setUp() public virtual override {
        BaseSetup.setUp();
        console.log("Setup1");

	vm.prank(alice);
        this.uploadObligation(bob, 42000, "alice to bob");
	vm.prank(bob);
        this.uploadObligation(carol, 69000, "bob to carol");
	vm.prank(carol);
        this.uploadObligation(alice, 10000, "carol to alice");
	console.log("Utilization Alice, Bob, Carol");
	console.logUint(utilization[bob][alice]);
	console.logUint(utilization[carol][bob]);
	console.logUint(utilization[alice][carol]);
    }
}
contract Cycle1 is Setup1 {
    function setUp() public virtual override {
        Setup1.setUp();
        console.log("Cycle1");
    }
    
    function testCycle() public {
	address[] memory path = new address[](4);
	path[0] = alice; path[1] = bob; path[2] = carol; path[3] = alice;
	// A cycle with 1 more would not be valid
	vm.expectRevert();
	applyCycle(path, 10001);
    }
    function testCycle2() public {
	address[] memory path = new address[](4);
	path[0] = alice; path[1] = bob; path[2] = carol; path[3] = alice;
	// This cycle should succeed
	validateCycle(path, 10000);
	
	vm.startBroadcast();
	applyCycle(path, 10000);
	vm.stopBroadcast();

	// This should now fail
	vm.expectRevert();
	applyCycle(path, 1);
    }
}
