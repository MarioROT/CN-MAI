import networkx as nx
import time
import matplotlib.pyplot as plt
import monte_carlo
import pandas as pd
import numpy as np
import utils
from utils import graph_dict, save_csv, save_network_to_pajek, plot_timesteps ,plot_beta_vs_p

rep=10 #100
t_max=1000
t_trans=900
p0=0.2
mu_values=[0.1,0.5,0.9]
betas_plot=[0.1,0.2,0.3,0.5,0.7,0.9] 
nodes=[800]
k_values=[3,5,9]
networks={}
for k in k_values:
    for node in nodes:
        p=k/(node-1)
        network= nx.erdos_renyi_graph(node, p)
        networks["(N="+str(node)+", K="+str(k)+")"]=network


for network_name in networks: 
    title="Erdos-Renyi "+network_name
    network=networks[network_name]
    print(f'-----Processing network {title} -----------')
    graph=utils.graph_dict(network)
    save_network_to_pajek(network, title)
    start_time = time.time()
    
    p_values_timesteps={}
    p_values_vs_beta=[]
    
    for mu in mu_values: 
        # B beta (at least 51 values, from 0 to 1)
        beta=0.0
        betas=[]
        p=[]
        for i in range(0,51):
            start_time_beta = time.time()
            MC=monte_carlo.MC_SIS(rep,t_max,t_trans,graph,mu,beta,p0)
            avg_p, sample_timesteps=MC.MC()
            
            total_time_beta = time.time() - start_time_beta
            betas.append(beta)
            p.append(avg_p)
            
            if  mu==0.5 and beta in betas_plot:
                p_values_timesteps[beta]=sample_timesteps
                    
            print(f'B: {beta}, average_p: {round(avg_p,2)}, time: {round(total_time_beta,2)}s')
            beta += 0.02
            beta=round(beta,2)
        
        total_time = time.time() - start_time
        total_time=round(total_time,2)
        print(f'total time: {total_time}')
        p_values_vs_beta.append(p)
        
    
    
    beta_values=np.linspace(0,1,51)
    p_values_timesteps=np.array(pd.DataFrame(p_values_timesteps)).T
    title2=title+f', SIS (RP, WOR, μ={mu}, ρ₀={p0})'
    save_csv(title2, ['beta','pvalue'], [beta_values,p_values_timesteps])
    plot_timesteps(betas_plot, p_values_timesteps, title2,True)
    plot_beta_vs_p(beta_values, p_values_vs_beta, mu_values, title,True)
    save_csv(title, ['beta','pvalue','mu'], [beta_values,p_values_vs_beta,mu_values])