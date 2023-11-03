import networkx as nx
import os
from web3 import Web3
from datetime import datetime

infura_url = f'{os.environ["ETH_RPC_URL"]}'
account = "0xB631410903788046E08ba59bd5Bb5eF12Be18539"
contract_addr="0x9cB05FA69B4D71f831b32f3DD87ECa0E93229515"
web3 = Web3(Web3.HTTPProvider(infura_url))

json_abi = '[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"count","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"volumeCleared","type":"uint256"}],"name":"CycleSetoff","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"debtor","type":"address"},{"indexed":false,"internalType":"address","name":"creditor","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"string","name":"memo","type":"string"}],"name":"UploadedObligation","type":"event"},{"inputs":[{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"applyCycle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"creditor","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"string","name":"memo","type":"string"}],"name":"uploadObligation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"utilization","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"validateCycle","outputs":[],"stateMutability":"view","type":"function"}]'

contract = web3.eth.contract(address=contract_addr, abi=json_abi)

privkeys = open('privkeys.txt').readlines()
addresses = [web3.eth.account.from_key(key.strip()).address for key in privkeys]

edges = [(0, 2), (0, 3), (0, 4), (0, 5), (0, 7), (0, 9), (1, 6), (1, 9), (2, 3), (2, 5), (2, 9), (3, 5), (4, 7), (5, 7), (6, 7), (8, 9)]

graph = nx.DiGraph()

for i,ii in enumerate(addresses):
    for j,jj in enumerate(addresses):
        if (i,j) not in edges and (j,i) not in edges: continue
        util = contract.functions.utilization(ii,jj).call()
        if util > 0:
            graph.add_edge(ii, jj, weight=util)
            
pos = nx.spring_layout(graph)
import matplotlib.pyplot as plt

plt.figure()
for n in graph.nodes():
    graph.nodes[n]
labeldict = dict((n, n[:5]+'...'+n[-3:]) for n in graph.nodes())
nx.draw(graph, pos=pos, with_labels=True, labels=labeldict)
blocknumber = web3.eth.block_number

now = datetime.now()
date = now.strftime("%Y-%m-%d-%H:%M")
plt.title(f'Graph as of {date}')
plt.savefig(f"graph-{date}.png", format="PNG")

