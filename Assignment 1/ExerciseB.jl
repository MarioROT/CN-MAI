include("NetworkProcessing.jl")
using CSV

graph, edge_weights, vertex_labels = NetworkProcessing.read_network("A1-networks/real/airports_UW.net")
df  = NetworkProcessing.nodes_num_descriptors(graph, edge_weights, vertex_labels,true)

CSV.write("ExerciseB_Results.csv", df)