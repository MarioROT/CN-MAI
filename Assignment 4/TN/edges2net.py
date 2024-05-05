def edges_to_net(edges_file, net_file):
    with open(edges_file, 'r') as f:
        lines = f.readlines()

    nodes = set()
    edges = []

    for line in lines:
        source, target = line.strip().split(',') #line.strip().split(',')  # Adjust split by comma
        nodes.add(source)
        nodes.add(target)
        edges.append((source, target))

    with open(net_file, 'w') as f:
        f.write('*Vertices {}\n'.format(len(nodes)))
        for node in nodes:
            f.write('{} "{}"\n'.format(node, node))

        f.write('*Edges\n')
        for edge in edges:
            f.write('{} {}\n'.format(edge[0],edge[1]))

# Example usage
edges_file = "ER_N500_k6.edges"
net_file = "ER_N500_k6.net"
edges_to_net(edges_file, net_file)
