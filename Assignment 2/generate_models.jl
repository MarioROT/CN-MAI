include("../Assignment 1/NetworkProcessing.jl")
include("NetworkModels.jl")
using Plots, GraphRecipes
using Graphs

models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(10,45), (20, 25), (20, 50), (20, 110), (50,180), (100, 250), (1000, 5000), (10000, 22000)]],
              "Erdos-Renyi/NP"=>[NetworkModels.erdos_renyi, [(10,0.9), (20, 0.3), (20, 0.6), (20, 0.9), (50,0.8), (100, 0.5), (1000, 0.1), (10000, 0.02)]],
               "Barabasi-Albert"=>[NetworkModels.barabasi_albert,[(10,30,5), (20,30,6), (20,30,12), (20,30, 18), (50,90, 12), (100, 120, 17), (5, 1000, 3), (50, 1000, 15, 1), (50, 10000, 8, 1)]],
               "Configuration-Model"=>[NetworkModels.configuration_model, [("power-law", 100, 20, 3.0),("power-law", 1000, 20, 2.7), ("power-law", 10000, 20, 2.9), ("power-law", 10000, 20, 3.5), ("poisson", 100, 30, 3.2), ("poisson", 1000, 20, 2), ("poisson", 10000, 20, 2), ("poisson", 10000, 20, 4)]],
              "Watts-Strogatz"=>[NetworkModels.small_world, [(50,2,0.0), (50,4,0.3), (100,4, 0.3), (100,4,0.5), (1000,6,0.5), (1000,6, 0.8), (10000,6, 0.9), (100000,6,1.0)]])

#models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(10,45), (50,180), (100, 250), (1000, 925), (10000, 3254)]])
              
save_model_dir = "GeneratedGraphs"
save_fig_dir = "GeneratedGraphsFigs"
save_pdf_dir = "PDFs"

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
        if (occursin("Erdos", k) && params[1] >= 1000  ) || (occursin("Bar", k) && params[2] >= 1000  ) || (occursin("Config", k) && params[2] <= 100  ) || (occursin("Watts", k) && params[1] <= 50 )
            dist_graph = NetworkProcessing.compute_experimental_degree_distribution(k, graph, params)
            NetworkProcessing.compute_theoretical_degree_distribution(k, graph, params)
            savefig(dist_graph, "$save_pdf_dir/$name2save.png")
        end
        println("- model generated with params: $params")
    end
end