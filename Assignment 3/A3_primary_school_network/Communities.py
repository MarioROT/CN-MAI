import networkx as nx
from community import community_louvain
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap


def load_network(file_path, name):
    G = nx.read_pajek(file_path)
    G = nx.Graph(G)
    member = community_louvain.best_partition(G)
    
    return pd.Series(member, name=name)

#Reading txt file with real communities
def reading_txt(file_path,all=True):
    real_comm = {}

    with open(file_path, "r") as file:
        skip_first_row = True
        for line in file:
            if skip_first_row:
                skip_first_row = False
                continue
            parts = line.split()
            
            if all==True and len(parts) == 2:
                first_char = parts[1][0]
                real_comm[parts[0]] = first_char
                
            else:
                real_comm[parts[0]]=parts[1]
                
    return pd.Series(real_comm, name='Real community')
                  
                
def generate_save_table(s1,s2,header,name):

    df = pd.concat([s1, s2], axis=1)
    df.reset_index(inplace=True)
    df.rename(columns={'index': 'Node'}, inplace=True)

    table = df.pivot_table(index=header, columns='Real community', values='Node', aggfunc='count')
    table.fillna(0, inplace=True)
    print(table)
    
    table.to_csv(name+'.csv')
    
    return table

def generate_stacked_bars(table, title):

    cmap = plt.cm.get_cmap('tab10')
    colors_indices = [0, 1, 2, 3, 5, 6]
    selected_colors = [cmap(i) for i in colors_indices]
    selected_cmap = ListedColormap(selected_colors)

    ax = table.T.plot(kind='bar', stacked=True, figsize=(10, 6),colormap=selected_cmap)
    ax.set_xlabel('Real communities')
    ax.set_ylabel('Number of real nodes')
    ax.set_title(title)
    plt.legend(title='Pred. comm.', bbox_to_anchor=(1, 1), loc='upper left')
    plt.show()
    
    plt.savefig(title+'.png', bbox_inches='tight')
  
    