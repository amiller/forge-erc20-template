# Fixed graph of edges
EDGES="[(0, 2), (0, 3), (0, 4), (0, 5), (0, 7), (0, 9), (1, 6), (1, 9), (2, 3), (2, 5), (2, 9), (3, 5), (4, 7), (5, 7), (6, 7), (8, 9)]"

# Select a random edge to submit obligations along
INDEX=$RANDOM
let "INDEX %= 10"

# Select a direction (since graph is bidirectional)
BIT=$RANDOM
let "BIT %= 2"
FROM=$(python -c "print(${EDGES}[$INDEX][$BIT])")
TO=$(python -c "print(${EDGES}[$INDEX][$((1-$BIT))])")

# Random amount for the new obligation
AMT=$RANDOM
let "AMT %= 1000"

# Private Key of FROM
PRIV_FROM=$(cat privkeys.txt | sed -n $((${FROM}+1))p)
# Address of TO
ADDR_TO=$(cast wallet a $(cat privkeys.txt | sed -n $((${TO}+1))p))

echo $PRIV_FROM $ADDR_TO $AMT

# Pre-prepared contract
# https://sepolia.etherscan.io/address/0x705ea078b2f82372247de2405305cae4192af444#code
CONTRACT=0x705ea078b2f82372247de2405305cae4192af444

set -x
cast send -c sepolia --private-key $PRIV_FROM $CONTRACT "uploadObligation(address,uint256,string)" $ADDR_TO $AMT "edge $INDEX"
