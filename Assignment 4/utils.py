import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import csv
import re

#It converts a graph object into a dictionary in a convenient format to implement the SIS model
def graph_dict(graph):
    g = {}

    for node in graph.nodes():
        info = {
        'neighbors': list(graph.neighbors(node)),
        'state': 'N'
        }
        g[node] = info

    return g

def plot_timesteps(betas, p_series, title,save_figure=True):
    
    if len(betas) != len(p_series):
        raise ValueError("Each beta value must correspond to one series of probabilities.")
    
    # Time steps
    t = np.arange(len(p_series[0]))
    
    plt.figure(figsize=(10, 6))
    colors = plt.cm.viridis(np.linspace(0, 1, len(betas)))  
    
    for beta, series, color in zip(betas, p_series, colors):
        plt.plot(t, series, label=f'β={beta:.2f}', color=color)
    
    plt.xlabel('t')
    plt.ylabel('p')
    plt.title(title)
    plt.legend(title='(β)')
    plt.grid(True)
    
    if save_figure:
        filename = re.sub('[^\w\-_\. ]', '_', title) + '.png'
        plt.savefig(filename, format='png', bbox_inches='tight')
        print(f"Figure saved as {filename}")
        
    plt.show()
    
def plot_beta_vs_p(beta_values, p_values, mu_values, title, save_figure=True):
   
    if len(p_values) != len(mu_values):
        raise ValueError("Each mu value must have a corresponding list of p values.")
    
    plt.figure(figsize=(10, 6))
    
    # Colors and markers can be customized for better visual distinction
    colors = ['blue', 'red', 'green']
    markers = ['o', '^', 's']  # Circle, triangle up, square
    
    for p_list, mu, color, marker in zip(p_values, mu_values, colors, markers):
        plt.plot(beta_values, p_list, label=f'μ={mu}', color=color, marker=marker, linestyle='-', linewidth=2, markersize=5)
    
    plt.xlabel('β')
    plt.ylabel('p')
    plt.title(title)
    plt.legend(title='(μ)')
    plt.grid(True)
     
    if save_figure:
        filename = re.sub('[^\w\-_\. ]', '_', title) + '.png'
        plt.savefig(filename, format='png', bbox_inches='tight')
        print(f"Figure saved as {filename}")
        
    plt.show()
 

def save_csv(filename, headers, data):
    
    with open(filename, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(data)

def save_network_to_pajek(G, filename):
    # Ensure the filename ends with .net
    filename = re.sub('[^\w\-_\. ]', '_', filename)
    if not filename.endswith('.net'):
        filename += '.net'
    
    try:
        nx.write_pajek(G, filename)
        print(f"Network saved successfully to {filename}")
    except Exception as e:
        print(f"An error occurred while saving the network: {str(e)}")