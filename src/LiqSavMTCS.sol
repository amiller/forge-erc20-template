pragma solidity ^0.8;

import {SimpleMTCS} from "./SimpleMTCS.sol";

contract LiqSavMTCS is SimpleMTCS {

    // # Part 1. Acceptances and Tenders
    /**
      We will now add two things.
      a. First, we'll allow people to make token deposits. These
      deposits can be used at any time to "settle" an obligation.
      b. Second, we'll allow for people to express their willingness to "accept" an obligation.
      These obligations can be created ("novated") to settle another.
     **/
    
    // ## Part 1.a. Handling deposits and withdrawals
    /**
       Here we are collecting native currency deposits. 
       (This is not actually ERC-20 token, but that is standard to add later).
       This is not doing any timelock on escrow. So you can withdraw at any time immediately.
       Note that without a timelock, this is very difficult for Solvers. State might change
          at any time.

	Rather than track balances in a separate data structure, we simply treat this
	contract address as the liquidity source for native tokens.
    **/

    function deposit() public payable {
	// When you deposit, you are the creditor and the contract is the lender
	utilization[msg.sender][address(this)] += msg.value;
    }
    function withdraw(uint amt) public {
	// Funds in your account can be withdrawn at any time
	require(utilization[msg.sender][address(this)] >= amt);
	utilization[msg.sender][address(this)] -= amt;
	payable(msg.sender).transfer(amt);
    }

    // ## Part 1.b. Setting acceptances
    
    // Set credit limits (these people are allowed to invoice you)
    // Mapping is from creditor to the debtor. These can change at any time.
    mapping ( address => mapping ( address => uint )) public creditLimits;
    function setAcceptance(address debtor, uint limit) public {
	creditLimits[msg.sender][debtor] = limit;
    }

    // # Part 2. Settling debts and liquidity injection.

    /**
       We now generalize the cycle in the two ways we've extended the graph.

       (I) Token deposits are now liquidity sources.
          We treat the bank as a liquidity source. We have already recordeded these as 
	  obligations in the graph.

       (II) We allow novations and acceptances.
           It is no longer the case that cycles must only decrease utilization.
	   Instead it is allowed to increase utilization, subject to an "acceptance" limit.


     To illustrate what this offers, we take a canonical scenario below that
     combines them both:

    	       Acceptance            Obligation
	   C  ---{$100}--->   A ===[$10]===> B
	   \\                              /
	    \<===[$20]=== $$$   <----inf--/
			   
	  
      The narrative here is that Alice owes Bob, the obligation ==[$10]==. 
      Carol has a deposit of ==$[20]== depicted as utilization from the bank.
      Carol offers an acceptances towards Alice, up to --{$100}-- depicted as dashed, since
      they can be exchanged for obligations in the other direction. Finally, to 
      finish explaining the cycle, note that we consider an infinite acceptance to the
      contract itself here... so the contract will always accept token payments to discharge
      an obligation.

      What have we gained by making this a cycle? The same mechanism of applying a cycle
      can now be used to unwind obligations.

       Note that it may be the case that the utilization both before and after the flow exceeds
       acceptances. Applying a cycle never creates an exceedance when there wasn't one. And
       it only reduces or leaves unchanged the amount.
    **/
    
    mapping(address => mapping(address => int256)) flow; // temporary

    function getCreditLimit(address creditor, address debtor) public view returns(uint) {
	if (debtor == address(this)) {
	    return 2**256-1;
	} else return creditLimits[creditor][debtor];
    }

    function min(uint a, uint b) public pure returns (uint) {
	if (a < b) return a; else return b;
    }
    

    function validateCycle(address[] memory path, uint amount) public view override {
	// Check this forms a cycle
	require(path[0] == path[path.length-1]);

	// TODO: FIXME: Check that except for start and stop, the same node
	// never appears twice in the list!
	
	// For each egde, we must check that *at least one* of the following must hold: 
	//   (1) the utilization is decreasing,
	//   (2) the new utilization is within acceptances
	for (uint i = 0; i < path.length-1; i++) {
	    address from = path[i];
	    address to = path[i+1];

	    // (1) a transfer from/to is applied to existing obligations
	    uint amt_setoff = min(amount, utilization[to][from]);
	    
	    // (2) any remainder is added to the opposite obligation, but must be within
	    //     acceptance
	    uint amt_novated = amount - amt_setoff;

	    // Remind the graph that each account is assumed to fully accept the contract
	    // Check the novation doesn't exceed acceptance
	    require(amt_novated + utilization[from][to] <= getCreditLimit(from,to));
	}
    }

    function applyCycle(address[] memory path, uint amount) public override {
	validateCycle(path, amount);
	uint count = path.length-1;
	uint volumeCleared = 0;
	for (uint i = 0; i < path.length-1; i++) {
	    address from = path[i];
	    address to = path[i+1];

	    // (1) a transfer from/to is applied to existing obligations
	    uint amt_setoff = min(amount, utilization[to][from]);
	    
	    // (2) any remainder is added to the opposite obligation, but must be within
	    //     acceptance
	    uint amt_novated = amount - amt_setoff;

	    // Remind the graph that each account is assumed to fully accept the contract
	    // Check the novation doesn't exceed acceptance
	    require(amt_novated + utilization[from][to] <= getCreditLimit(from,to));

	    utilization[to][from] -= amt_setoff;
	    utilization[from][to] += amt_novated;
	    volumeCleared += amount;
	}
	emit CycleSetoff(count, volumeCleared);
    }
    

    /*function validateFlow(address[] memory froms,
			  address[] memory tos,
			  uint[] memory amts) public view returns(bool)
    {
	// Ensure arrays have the same length
	require(froms.length == tos.length && tos.length == amts.length, "Array lengths must match");
	
	// Data structure to keep track of net flow per address, and total flow on each edge
	for (uint256 i = 0; i < froms.length; i++) {
	    address from = froms[i];
	    address to = tos[i];
            netFlows[from] = 0;
	    netFlows[to] = 0;
	    flow[from][to] = 0;
	    flow[to][from] = 0;
	}
	
	// 1. Calculate the net flow for each address
	for (uint256 i = 0; i < froms.length; i++) {
            netFlows[froms[i]] -= int256(amts[i]); // Subtracting amount for sender
            netFlows[tos[i]] += int256(amts[i]);   // Adding amount for receiver
	}
	
	// Check if each address is net neutral or net positive
	for (uint256 i = 0; i < froms.length; i++) {
            if (netFlows[froms[i]] < 0 || netFlows[tos[i]] < 0) {
		return false; // If any address has a net negative flow, validation fails
            }
	}
	
	// 2. Check that novation does not exceed acceptances
	for (uint256 i = 0; i < froms.length; i++) {
	    address from = froms[i];
	    address to = tos[i];
	    
	    // Here, we're updating the flow for each unique pair of from and to addresses
	    // This will record the flow (amount transferred) between each pair
	    flow[from][to] += amts[i];

	    // A net flow must be positive and in only one direction. Check each time
	    require(flow[to][from] == 0);
	}

	for (uint256 i = 0; i < froms.length; i++) {
	    address from = froms[i];
	    address to = tos[i];

	    // First we need to count against any net debt
	    uint 
	    bool within_acceptance = (flow[from][to] + utilization[from][to] <=
				      acceptances[from][to]);

	    // Net position (positive here is good, a payment pays off debt)
	    int256 net = (int256(utilization[to][from]) -
			  int256(utilization[from][to]));


	    flow[from][to] += amts[i];
	}
    }*/
    
}
