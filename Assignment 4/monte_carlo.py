import numpy as np

class MC_SIS(object):

    def __init__(self, rep, t_max, t_trans, graph, mu, beta, p0):
        self.rep = rep
        self.t_max = t_max
        self.t_trans = t_trans
        self.graph = graph
        self.mu = mu
        self.beta = beta
        self.p0 = p0
        self.num_nodes = len(self.graph)

        self.state_cero()

    #Initial state of Suceptible or Infeted depending on initial probability p0
    def state_cero(self):
        self.infected_nodes=[]
        self.susceptible_nodes=[]

        for node in self.graph:
            if np.random.rand()<self.p0:
                self.graph[node]['state']='I'
                self.infected_nodes.append(node)
                
            else:
                self.graph[node]['state']='S'
                self.susceptible_nodes.append(node)
        
    
    def state_t_plus_one(self):
    
        next_step_infected_nodes = []
        next_step_susceptible_nodes = []

        for infected in self.infected_nodes:
            if np.random.random() < self.mu:
                next_step_susceptible_nodes.append(infected) 
            else:
                next_step_infected_nodes.append(infected) 

        # infect nodes
        for susc_node in self.susceptible_nodes:
            infected = False
            neighbors = self.graph[susc_node]['neighbors']

            i = 0
            while i < len(neighbors) and not infected:
                if self.graph[neighbors[i]]['state'] == 'I':
                    infected = np.random.random() < self.beta
                i += 1

            if infected:
                next_step_infected_nodes.append(susc_node)
            else:
                next_step_susceptible_nodes.append(susc_node)

        #Update the new state for next time step of the nodes in the dict
        for node in next_step_infected_nodes:
            self.graph[node]['actual_state'] = 'I'

        for node in next_step_susceptible_nodes:
            self.graph[node]['actual_state'] = 'S'

        #Update the t+1 lists of node with the calculation for the next iteration
        self.infected_nodes = next_step_infected_nodes
        self.susceptible_nodes = next_step_susceptible_nodes

        p = float(len(self.infected_nodes)/ self.num_nodes)
        
        return p

    def MC(self):
        numerator = 0
        avg_infected_nodes = []

        for i in range(self.rep):
            total_steps = []
            for step in range(self.t_max):
                p = self.state_t_plus_one()
                total_steps.append(p)
            stationary_steps = total_steps[self.t_trans:]
            average_infected_nodes = sum(stationary_steps) / len(stationary_steps)
            numerator += average_infected_nodes
            # restart model for next iteration
            self.state_cero()

        average_p = numerator / self.rep

        return average_p , total_steps