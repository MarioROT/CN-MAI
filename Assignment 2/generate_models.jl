include("../Assignment 1/NetworkProcessing.jl")
include("NetworkModels.jl")
using Plots, GraphRecipes

models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(10,45), (20, 25), (20, 50), (20, 110), (50,180), (100, 250), (1000, 925), (10000, 3254)]],
              "Erdos-Renyi/NP"=>[NetworkModels.erdos_renyi, [(10,0.9), (20, 0.3), (20, 0.6), (20, 0.9), (50,0.8), (100, 0.5), (1000, 0.4), (10000, 0.2)]],
              "Barabasi-Albert"=>[NetworkModels.barabasi_albert,[), (10,30,5(20,30,6), (20,30,12), (20,30, 18), (50,90, 12), (100, 120, 17), (1000, 1980, 18), (10000, 15000, 19)]])
#models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(10,45), (50,180), (100, 250), (1000, 925), (10000, 3254)]])

save_model_dir = "GeneratedGraphs"
save_fig_dir = "GeneratedGraphsFigs"

for (k,v) in models
    model, parameter_list = v
    println("\n\n--- Generating models with $model algorithm!")
    for params in parameter_list
        name2save = (k*"/"*split(k,"/")[1]*"_"*join(params, "_"))
        graph = model(params...)
        NetworkProcessing.save_network(graph, "$save_model_dir/$name2save.net")
        if (params[1] <= 50 && occursin("Erdos", k)) || (params[2] <= 100 && occursin("Bar", k))
            savefig(graphplot(graph, curves = false), "$save_fig_dir/$name2save.png")
        end
        println("- model generated with params: $params")
    end
end