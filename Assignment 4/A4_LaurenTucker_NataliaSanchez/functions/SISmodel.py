from functions.DiffusionModel import DiffusionModel
import numpy as np
import future.utils

class SISModel(DiffusionModel):
    """
    Model Parameters to be specified via ModelConfig

    beta: The infection rate (float value in [0,1])
    lambda: The recovery rate (float value in [0,1])
    """

    def __init__(self, graph, seed=None):
        """
        Model Constructor

        graph: A networkx graph object
        """
        super(self.__class__, self).__init__(graph, seed)
        self.available_statuses = {"Susceptible": 0, "Infected": 1}

        self.parameters = {
            "model": {
                "beta": {"descr": "Infection rate", "range": [0, 1], "optional": False},
                "mu": {"descr": "Recovery rate", "range": [0, 1], "optional": False}},
            "nodes": {},
            "edges": {},
        }

        self.name = "SIS"

    def iteration(self, node_status=True):
        """
        Execute a single model iteration

        :return: Iteration_id, Incremental node status (dictionary node->status)
        """
        self.clean_initial_status(self.available_statuses.values())

        actual_status = {
            node: nstatus for node, nstatus in future.utils.iteritems(self.status)
        }

        if self.actual_iteration == 0:
            self.actual_iteration += 1
            delta, node_count, status_delta = self.status_delta(actual_status)
            if node_status:
                return node_count.copy()[1]/sum(node_count.values())
            else:
                return node_count.copy()[1]/sum(node_count.values())

        for u in self.graph.nodes:

            u_status = self.status[u]
            eventp = np.random.random_sample()
            neighbors = self.graph.neighbors(u)
            if self.graph.directed:
                neighbors = self.graph.predecessors(u)

            if u_status == 0:
                infected_neighbors = [v for v in neighbors if self.status[v] == 1]
                for i in range(len(infected_neighbors)):
                    eventp = np.random.random_sample()
                    if eventp < self.params["model"]["beta"]:
                        actual_status[u] = 1
            elif u_status == 1:
                if eventp < self.params["model"]["mu"]:
                    actual_status[u] = 0

        delta, node_count, status_delta = self.status_delta(actual_status)
        self.status = actual_status
        self.actual_iteration += 1

        if node_status:
            return node_count.copy()[1]/sum(node_count.values())
        else:
            return node_count.copy()[1]/sum(node_count.values())
