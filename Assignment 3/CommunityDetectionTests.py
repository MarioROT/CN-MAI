import os
import matplotlib.pyplot as plt
from NetworksCommunityDetection import load_network, detect_communities, calculate_metrics, visualize_communities

networks = os.listdir('A3_synthetic_networks')

metrics = {'network':[],
           'Inf-nmi':[], 'Inf-ari':[], 'Inf-jaccard':[],
           'Lou-nmi':[], 'Lou-ari':[], 'Lou-jaccard':[],
           'Lei-nmi':[], 'Lei-ari':[], 'Lei-jaccard':[],
           'Agg-nmi':[], 'Agg-ari':[], 'Agg-jaccard':[]}
methods = ['Infomap', 'Louvain', 'Leiden', 'agglomerative']

for network in networks:
    print(f'--- Processing Network: {network}...')
    for method in methods:
        print(f'- Using method: {method}...')
        metrics['network'].append(network)
        G = load_network(f'A3_synthetic_networks/{network}')
        true_partition = {node: node // 60 for node in G.nodes()} 
         
        detected_partition = detect_communities(G, method.lower())
        nmi, ari, ji = calculate_metrics(true_partition, detected_partition)
        metrics[method[:3] + 'nmi'], metrics[method[:3] + 'ari'], metrics[method[:3] + 'jaccard'] = nmi, ari, ji
        visualize_communities(G, detected_partition, f"Community Structure Detected by {method}", show = False)
        
        plt.savefig(f'SyntheticNetworksFigs/{method}/{network[:-3]}.png')
