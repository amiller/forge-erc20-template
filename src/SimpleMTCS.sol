interface IERC20Token {
}

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

    

    // Set credit limits (these people are allowed to invoice you)
    // Mapping is from creditor to the debtor.
    mapping ( address => mapping ( address => uint )) public creditLimits;
    function setAcceptance(address debtor, uint limit) public {
	if (!isUser(msg.sender)) addUser(msg.sender);
	if (!isUser(debtor)) addUser(debtor);
	// This sets the credit limit
	creditLimits[msg.sender][debtor] = limit;
    }
    

    function validateCycle(address[] memory froms, address[] memory tos, uint[] memory amts) public view {
	// Check this forms a cycle
	// Check the cycle satisfies constraints
    }
    function applyCycle(address[] memory froms, address[] memory tos, uint[] memory amts) public {
	validateCycle(froms, tos, amts);
	// Apply the cycle
    }
}
