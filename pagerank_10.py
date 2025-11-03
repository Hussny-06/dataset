import networkx as nx 

# Create a directed graph 
G = nx.DiGraph() 

# Add edges between pages
G.add_edges_from([('A', 'B'), ('A', 'C'), ('B', 'C'), ('C', 'A')])

# Calculate PageRank 
pagerank = nx.pagerank(G, alpha=0.85)

# Print the PageRank for each page 
print("PageRank Scores:", pagerank)