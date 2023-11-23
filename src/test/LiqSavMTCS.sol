// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {console} from "forge-std/console.sol";
import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";

import {Utils} from "./utils/Utils.sol";
import {LiqSavMTCS} from "../LiqSavMTCS.sol";

contract BaseSetup is LiqSavMTCS, Test {
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

	// Alice owes Bob
	vm.prank(alice);
        this.uploadObligation(bob, 42000, "alice to bob");

	// Carol has deposited some coins
	vm.prank(carol);
        this.deposit{value: 10000}();

	// Carol expresses an acceptance of obligations from Alice
	vm.prank(carol);
        this.setAcceptance(alice, 50000);

	if (false) {
	    console.log("Utilization Alice, Bob, Carol");
	    console.logUint(utilization[bob][alice]);
	    console.logUint(utilization[carol][bob]);
	    console.logUint(utilization[alice][carol]);
	}
	if (false) {
	    console.log("Bank balances Alice, Bob, Carol");
	    console.logUint(utilization[alice][address(this)]);
	    console.logUint(utilization[bob][address(this)]);
	    console.logUint(utilization[carol][address(this)]);
	}
	if (false) {
	    console.log("Acceptances Alice-> Bob -> Carol");
	    console.logUint(creditLimits[alice][bob]);
	    console.logUint(creditLimits[bob][carol]);
	    console.logUint(creditLimits[carol][alice]);
	}
    }
}
contract LiqSav1 is Setup1 {
    
    function setUp() public virtual override {
        Setup1.setUp();
        console.log("LiqSav1");
    }

    function testPath() internal view returns (address[] memory) {
 	address[] memory path = new address[](5);
	path[0] = alice; path[1] = bob; path[2] = address(this);
	path[3] = carol; path[4] = alice;
	return path;
    }

    function testFlow1() public {
	address[] memory path = testPath();

	// This is the best cycle we can apply
	validateCycle(path, 10000);

	// One more would fail
	vm.expectRevert();
	validateCycle(path, 10001);
    }

    function testFlow3() public {
	address[] memory path = testPath();

	// Carol expresses an acceptance of obligations from Alice
	vm.prank(carol);
        this.setAcceptance(alice, 5000);

	// This is the best cycle we can apply
	validateCycle(path, 5000);

	// One more would fail
	vm.expectRevert();
	validateCycle(path, 5001);
    }
    
    function testFlow2() public {
	/* It should be considered feasible to reduce Alice's unaccepted debt,
	   by replacing it with accepted debt. 

    	       Acceptance        Obligation
	   C  ---{$50}--->   A ===[$42]===> B
	   \\                              /
	    \<===[$10]=== $$$   <----inf--/

	   Initially: 
	   
	*/
	address[] memory path = testPath();
	applyCycle(path, 5000);

	// The result:
	//   Bob should have 5000 coins,
	//   Carol should have 5000 left.
	//   Only 37k remain of Alice's debt to Bob
	//   Alice now owes Carol 5k though
	assertEq(utilization[bob][address(this)], 5000);
	assertEq(utilization[carol][address(this)], 5000);
	assertEq(utilization[carol][alice], 5000);
	assertEq(utilization[bob][alice], 37000);
	
    }
}
