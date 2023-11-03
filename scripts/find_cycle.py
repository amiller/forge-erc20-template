import networkx as nx

def find_flow(g):
    # Add up the n
    g = g.copy()
    # Net outgoing
    nets = dict((n,0) for n in g.nodes())

    for (u,v) in g.edges():
        nets[u] += g.edges[u,v]['weight']
        nets[v] -= g.edges[u,v]['weight']
    
    for n in list(g.nodes()):
        if nets[n] >= 0:
            g.add_edge('SOURCE', n, weight=nets[n])
        else:
            g.add_edge(n, 'SINK', weight=-nets[n])

    max_flow = nx.max_flow_min_cost(g, 'SOURCE','SINK',capacity='weight')    
    # print(max_flow)

    resid = g.copy()
    for u in max_flow:
        for v,amt in max_flow[u].items():
            resid.edges[u,v]['weight'] -= amt

    # Every edge in the residual graph is part of a cycle
    cycles = list(nx.simple_cycles(resid))
    wcycles = []
    for cycle in cycles:
        amt = 1e10
        for u,v in zip(cycle,cycle[1:]+cycle[:1]):
            amt = min(amt, resid.edges[u,v]['weight'])
        if amt > 0:
            wcycles.append((amt, cycle))
    wcycles.sort(reverse=True)
    for cycle in wcycles:
        print(cycle)

