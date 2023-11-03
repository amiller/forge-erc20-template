#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

forge create ./src/SimpleMTCS.sol:SimpleMTCS -i --rpc-url 'https://sepolia.infura.io/v3/'${INFURA_API_KEY} --private-key ${PRIVATE_KEY}

# 0xB631410903788046E08ba59bd5Bb5eF12Be18539
# address
