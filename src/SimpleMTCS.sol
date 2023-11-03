pragma solidity ^0.8;

contract SimpleMTCS { 

    // Upload obligations you intend to pay
    // Mapping[Creditor][Debtor]=>Balance
    mapping ( address => mapping (address => uint)) utilization;
    event UploadedObligation(address debtor, address creditor, uint amount, string memo);
    function uploadObligation(address creditor, uint amount, string calldata memo) public {
	// I'm the debtor, I will pay the creditor this much.
	// Modify the graph
	utilization[creditor][msg.sender] += amount;
	// Emit an event about this particular invoice
	emit UploadedObligation(msg.sender, creditor, amount, memo);
    }

    function validateCycle(address[] memory path, uint amount) public view {
	// Check this forms a cycle
	require(path[0] == path[path.length-1]);
	// For each item, we must be sure the utilization decreases
	for (uint i = 0; i < path.length-1; i++) {
	    address from = path[i];
	    address to = path[i+1];
	    // Transfer from/to must reduce an obligation
	    require(amount <= utilization[to][from], "clearing too much");
	}
    }

    event CycleSetoff(uint count, uint volumeCleared);
    function applyCycle(address[] memory path, uint amount) public {
	validateCycle(path, amount);
	// Apply the cycle
	uint count = path.length-1;
	uint volumeCleared = 0;
	for (uint i = 0; i < path.length-1; i++) {
	    address from = path[i];
	    address to = path[i+1];
	    utilization[to][from] -= amount;
	    volumeCleared += amount;
	}
	emit CycleSetoff(count, volumeCleared);
    }
}
