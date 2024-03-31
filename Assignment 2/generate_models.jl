include("../Assignment 1/NetworkProcessing.jl")
include("NetworkModels.jl")
using Plots, GraphRecipes

models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(10,45), (100,450)]],
              "Erdos-Renyi/NP"=>[NetworkModels.erdos_renyi, [(10,1.0), (20,0.4)]],
              "Barabasi-Albert"=>[NetworkModels.barabasi_albert,[(10,20,3), (20,40,6)]])

save_model_dir = "GeneratedGraphs"
save_fig_dir = "GeneratedGraphsFigs"

for (k,v) in models
    model, parameter_list = v
    println("\n\n--- Generating models with $model algorithm!")
    for params in parameter_list
        name2save = (k*"/"*split(k,"/")[1]*"_"*join(params, "_"))
        graph = model(params...)
        NetworkProcessing.save_network(graph, "$save_model_dir/$name2save.net")
        savefig(graphplot(graph, curves = false), "$save_fig_dir/$name2save.png")
        println("- model generated with params: $params")
    end
end