include("../Assignment 1/NetworkProcessing.jl")
include("NetworkModels.jl")
using Plots, GraphRecipes


models = Dict("Configuration-Model"=>[NetworkModels.configuration_model, [("power-law", 100, 20, 3.0),("power-law", 1000, 20, 2.7), ("power-law", 10000, 20, 2.9), ("power-law", 10000, 20, 3.5), ("poisson", 100, 30, 3.2), ("poisson", 1000, 20, 2), ("poisson", 10000, 20, 2), ("poisson", 10000, 20, 4)]],
              "Watts-Strogatz"=>[NetworkModels.small_world, [(50,2,0.0), (50,4,0.3), (100,4, 0.3), (100,4,0.5), (1000,6,0.5), (1000,6, 0.8), (10000,6, 0.9), (100000,6,1.0)]])

save_model_dir = "GeneratedGraphs"
save_fig_dir = "GeneratedGraphsFigs"

for (k,v) in models
    model, parameter_list = v
    println("\n\n--- Generating models with $model algorithm!")
    for params in parameter_list
        name2save = (k*"/"*split(k,"/")[1]*"_"*join(params, "_"))
        graph = model(params...)
        NetworkProcessing.save_network(graph, "$save_model_dir/$name2save.net")
        if (occursin("Config", k) && params[2] <= 100000  ) || (occursin("Watts", k) && params[1] <= 10000 )
            savefig(graphplot(graph, curves = false), "$save_fig_dir/$name2save.png")
        end
        println("- model generated with params: $params")
    end
end
