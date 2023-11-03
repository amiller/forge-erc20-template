import networkx as nx
import os
from web3 import Web3
from datetime import datetime

infura_url = f'wss://ethereum-sepolia.publicnode.com'
account = "0xB631410903788046E08ba59bd5Bb5eF12Be18539"
contract_addr="0x9cB05FA69B4D71f831b32f3DD87ECa0E93229515"
web3 = Web3(Web3.WebsocketProvider(infura_url))

json_abi = '[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"count","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"volumeCleared","type":"uint256"}],"name":"CycleSetoff","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"debtor","type":"address"},{"indexed":false,"internalType":"address","name":"creditor","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"string","name":"memo","type":"string"}],"name":"UploadedObligation","type":"event"},{"inputs":[{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"applyCycle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"creditor","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"string","name":"memo","type":"string"}],"name":"uploadObligation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"utilization","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"validateCycle","outputs":[],"stateMutability":"view","type":"function"}]'

contract = web3.eth.contract(address=contract_addr, abi=json_abi)

#privkeys = open('privkeys.txt').readlines()
#addresses = [web3.eth.account.from_key(key.strip()).address for key in privkeys]
addresses = ['0xB631410903788046E08ba59bd5Bb5eF12Be18539', '0x27B9d1cb6CB817616cB183D56B2f2D9D0dF1f812', '0x968Dd1b56fC4cC4b57D02eE488993F495FE2186d', '0x79200e45cECB37eCFe159F84c3b5EA846EC2e0d6', '0xf9D707E0af896df2BeDF0930c118E6012a66577c', '0x9634a62D8dE83AF4a034a2698207a2645A7E0839', '0xDcb646be830e7A4bd0Abf11d195245c2614C9506', '0x6ba768965c20939b895239F35665D2A51C21eb8c', '0x67c1480252bf01334aEB6DA107Acd78046EdA581', '0xEB5EdA8Dc6852035468424Dd0c76785bf204aF14', '0x2EDdAe6C33Ad35da6E095DF7abCC22B0445b80e8']

edges = [(0, 2), (0, 3), (0, 4), (0, 5), (0, 7), (0, 9), (1, 6), (1, 9), (2, 3), (2, 5), (2, 9), (3, 5), (4, 7), (5, 7), (6, 7), (8, 9)]

graph = nx.DiGraph()

for i,ii in enumerate(addresses):
    for j,jj in enumerate(addresses):
        if (i,j) not in edges and (j,i) not in edges: continue
        util = contract.functions.utilization(ii,jj).call()
        if util > 0:
            graph.add_edge(ii, jj, weight=util)
            

if __name__ == '__main__':
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

