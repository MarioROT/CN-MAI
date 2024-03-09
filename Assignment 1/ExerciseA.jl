include("NetworkProcessing.jl")
using CSV

net_descriptors = Dict{String, Vector}()
for dir in readdir("A1-Networks")
    for file in readdir("A1-networks/$dir")
        println("Processing $file...")
        graph, edge_weights = NetworkProcessing.read_weighted_net("A1-networks/$dir/$file")
       net_descriptors[file] = NetworkProcessing.network_num_descriptors(graph, false)
    end
end

df = NetworkProcessing.construct_df(net_descriptors, ["# Nodes", "# Edged", "Degree (min)", "Degree (max)", "Degree (avg)", "ACC", "Assort.", "APL", "Diameter"])

CSV.write("ExerciseA_Results.csv", df)

println(df)