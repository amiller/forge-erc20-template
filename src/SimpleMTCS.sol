pragma solidity ^0.8;

contract SimpleMTCS { 

    address[] public allUsers;
    // This is a mapping from users to their index in this array. It's hazardprone
    mapping (address => uint) _userIndex;
    function isUser(address a) view public returns(bool) { return _userIndex[a] != 0; }
    function userIndex(address a) view public returns(uint) { return _userIndex[a]-1; }
    function addUser(address a) public { _userIndex[a] = allUsers.length+1; allUsers.push(a); }


    // Deposit/Withdraw.
    // Here is just collecting native currency instead of a token, but the change is trivial
    // This is not doing any timelock on escrow. So you can withdraw at any time immediately.
    mapping (address => uint) public balances;
    function deposit() public payable {
	balances[msg.sender] += msg.value;
    }
    function withdraw(uint amt) public {
	// Funds deposited can be withdrawn at any time
	require(balances[msg.sender] >= amt);
	balances[msg.sender] -= amt;
	payable(msg.sender).transfer(amt);
    }

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
    

    // At any time, we can settle an obligation, transferring native units.
    // This decreases the utilized credit
    event Settled(address creditor, address debtor, uint amt);
    function settleObligation(address creditor, address debtor, uint amt) public {
	// A debtor can have their obligations settled at any time,
	// by transferring a portion of their balance.
	require(balances[debtor] >= amt);
	require(utilization[creditor][debtor] >= amt);

	// transfer balance
	balances[debtor] -= amt;
	balances[creditor] += amt;
	// decrease utilization
	utilization[creditor][debtor] -= amt;

	// Emit an event about this settle off
	emit Settled(creditor, debtor, amt);
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
