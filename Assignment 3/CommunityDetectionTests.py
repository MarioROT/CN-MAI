import os
import matplotlib.pyplot as plt
import pandas as pd
from NetworksCommunityDetection import load_network, detect_communities, calculate_metrics, visualize_communities, compute_modularity_groups

networks = os.listdir('A3_synthetic_networks')

metrics = {'network':[],
           'Inf-nmi':[], 'Inf-nvi':[], 'Inf-jaccard':[],
           'Lou-nmi':[], 'Lou-nvi':[], 'Lou-jaccard':[],
           'Lei-nmi':[], 'Lei-nvi':[], 'Lei-jaccard':[],
           'Agg-nmi':[], 'Agg-nvi':[], 'Agg-jaccard':[]}

mod_groups = {'network':[],
           'Inf-mod':[], 'Inf-groups':[],
           'Lou-mod':[], 'Lou-groups':[],
           'Lei-mod':[], 'Lei-groups':[],
           'Agg-mod':[], 'Agg-groups':[]}


methods = ['Infomap', 'Louvain', 'Leiden', 'Agglomerative']

for network in networks:
    print(f'--- Processing Network: {network}...')
    metrics['network'].append(network)
    mod_groups['network'].append(network)
    for method in methods:
        print(f'- Using method: {method}...')
        G = load_network(f'A3_synthetic_networks/{network}')
        true_partition = {node: node // 60 for node in G.nodes()} 
         
        detected_partition = detect_communities(G, method.lower())
        mod, gr = compute_modularity_groups(G, detected_partition)
        mod_groups[method[:3] + '-mod'].append(mod), mod_groups[method[:3] + '-groups'].append(gr)
        nmi, ari, ji = calculate_metrics(true_partition, detected_partition)
        metrics[method[:3] + '-nmi'].append(nmi), metrics[method[:3] + '-nvi'].append(ari), metrics[method[:3] + '-jaccard'].append(ji)
        visualize_communities(G, detected_partition, f"Community Structure Detected by {method}", show = False)
        
        plt.savefig(f'SyntheticNetworksFigs/{method}/{network[:-3]}.png')
        
pd.DataFrame(metrics).to_csv('CommunityDetectionResults.csv', index=False)
pd.DataFrame(mod_groups).to_csv('GroupsResults.csv', index=False)
