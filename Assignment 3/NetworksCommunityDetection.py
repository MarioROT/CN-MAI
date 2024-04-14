import networkx as nx
import community as community_louvain
import matplotlib.pyplot as plt
from sklearn.metrics import normalized_mutual_info_score, adjusted_rand_score
from infomap import Infomap
import numpy as np
import community as community_louvain
import leidenalg as la
import igraph as ig
from scipy.cluster.hierarchy import fcluster
from scipy.cluster.hierarchy import linkage
from scipy.spatial.distance import pdist

def load_network(file_path):
    # Load a network from a Pajek .net file
    G = nx.read_pajek(file_path)
    # Convert the network to an undirected graph, if necessary
    if isinstance(G, nx.DiGraph):
        G = G.to_undirected()
    # Pajek files often label nodes with strings, ensure they are consistent integers if needed
    G = nx.convert_node_labels_to_integers(G, first_label=0)
    return G

def detect_communities(G, method='louvain'):
    if method == 'louvain':
        partition = community_louvain.best_partition(G)
    elif method == 'infomap':
        infomap = Infomap(silent=True)
        # Ensure that node labels are converted to integers if they are not already
        for edge in G.edges():
            u, v = map(int, edge)  # Convert edge endpoints to integers
            infomap.add_link(u, v)
        infomap.run()
        # Mapping node to module with proper node type handling
        partition = {int(node): module for node, module in infomap.get_modules().items()}
    elif method == 'agglomerative':
        linkage_matrix = linkage(pdist(nx.to_numpy_array(G)), method='ward')
        cutoff = 1.5  
        # Determine clusters from the linkage matrix Z at a given cutoff
        clusters = fcluster(linkage_matrix, cutoff, criterion='distance')
        # Create a partition dictionary mapping nodes to their cluster
        partition = {node: clusters[i] for i, node in enumerate(G.nodes())}
    elif method == 'leiden':
        # Convert NetworkX graph to an igraph graph
        ig_graph = ig.Graph.TupleList(G.edges(), directed=False)
        partition = la.find_partition(ig_graph, la.ModularityVertexPartition)
        # Convert partition to the same format used in NetworkX
        partition = {node.index: partition.membership[node.index] for node in ig_graph.vs}
    else:
        raise ValueError("Unsupported method: Choose 'louvain' or 'infomap'")
    return partition

def visualize_communities(G, partition, title, show = True):
    if not all(node in partition for node in G.nodes()):
        missing_nodes = [node for node in G.nodes() if node not in partition]
        print(f"Warning: Nodes missing in partition: {missing_nodes}")
        for node in missing_nodes:
            partition[node] = -1  # Assigning a default community for missing nodes
    
    # Ensure node labels are consistent for mapping colors
    unique_communities = list(set(partition.values()))
    if "Agglomerative" in title:
        community_index = {node: community for node, community in partition.items()}
        colors = [community_index.get(node, 0) for node in G.nodes()]
    else:
        community_index = {comm: idx for idx, comm in enumerate(unique_communities)}
        colors = [community_index[partition[node]] for node in G.nodes()]

    # Generate position map for consistent node positions
    pos = nx.spring_layout(G, seed=42)  # Use a fixed seed for reproducible layout

    # Create a new figure and Axes for drawing
    fig, ax = plt.subplots(figsize=(10, 8))
    cmap = plt.get_cmap('viridis', len(unique_communities))
    
    # Drawing the nodes
    nx.draw_networkx_nodes(G, pos, ax=ax, node_color=colors, cmap=cmap, node_size=40, alpha=0.8)
    
    # Drawing the edges
    nx.draw_networkx_edges(G, pos, ax=ax, alpha=0.5)

    # Setting up the color bar
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=min(colors), vmax=max(colors)))
    sm.set_array([])
    
    cbar = fig.colorbar(sm, ax=ax, orientation='vertical', fraction=0.025, pad=0.05)
    cbar.set_label('Community ID')

    ax.set_title(title)
    ax.axis('off')  # Turn off the axis
    
    if show:
        plt.show()
    
def jaccard_index(set1, set2):
    """Calculate the Jaccard Index between two sets."""
    intersection = len(set1.intersection(set2))
    union = len(set1.union(set2))
    if union == 0:
        return 0
    else:
        return intersection / union

def partition_to_sets(partition):
    """Convert a partition dictionary to a list of sets."""
    from collections import defaultdict
    community_dict = defaultdict(set)
    for node, community in partition.items():
        community_dict[community].add(node)
    return list(community_dict.values())

from sklearn.metrics import jaccard_score

def compare_communities(community_sets_true, community_sets_computed):
    """Compare two lists of community sets and return average Jaccard Index."""
    jaccard_scores = []
    for set_true in community_sets_true:
        max_jaccard = 0
        for set_computed in community_sets_computed:
            score = jaccard_index(set_true, set_computed)
            if score > max_jaccard:
                max_jaccard = score
        jaccard_scores.append(max_jaccard)
    return sum(jaccard_scores) / len(jaccard_scores) if jaccard_scores else 0

def calculate_metrics(true_partition, detected_partition):
    difference = list(set(true_partition.keys()) - set(detected_partition.keys()))
    
    true_labels = [true_partition[node] for node in sorted(true_partition) if node not in difference]
    detected_labels = [detected_partition[node] for node in sorted(detected_partition)]
    
    nmi = normalized_mutual_info_score(true_labels, detected_labels)
    ari = adjusted_rand_score(true_labels, detected_labels)
    
    true_sets = partition_to_sets(true_partition)
    computed_sets = partition_to_sets(detected_partition)
    jaccard_idx = compare_communities(true_sets, computed_sets)
    
    return nmi, ari, jaccard_idx