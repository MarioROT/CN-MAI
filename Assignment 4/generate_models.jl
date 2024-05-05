include("../Assignment 1/NetworkProcessing.jl")
include("../Assignment 2/NetworkModels.jl")
using Plots, GraphRecipes
using Graphs

models = Dict("Erdos-Renyi/NK"=>[NetworkModels.erdos_renyi, [(500,25), (500, 50), (700, 40), (700, 80)]]
                "Erdos-Renyi/NP"=>[NetworkModels.erdos_renyi, [(500,0.3), (500, 0.7), (700, 0.3), (700,0.7)]],
               "Barabasi-Albert"=>[NetworkModels.barabasi_albert,[(50, 600, 6), (50, 600, 9, 1)]],
               "Configuration-Model"=>[NetworkModels.configuration_model, [("power-law", 700, 8, 3.0),("power-law", 700, 10, 3.0)]])
              
save_model_dir = "Networks"
save_fig_dir = "NetworksFigs"
save_pdf_dir = "PDFs"

for (k,v) in models
    model, parameter_list = v
    println("\n\n--- Generating models with $model algorithm!")
    for params in parameter_list
        name2save = (k*"/"*split(k,"/")[1]*"_"*join(params, "_"))
        graph = model(params...)
        NetworkProcessing.save_network(graph, "$save_model_dir/$name2save.net")
        if (occursin("Erdos", k) && params[1] <= 50) || (occursin("Bar", k) && params[2] <= 100) || (occursin("Config", k) && params[2] <= 100  ) || (occursin("Watts", k) && params[1] <= 50)
            savefig(graphplot(graph, curves = false), "$save_fig_dir/$name2save.png")
        end
        if (occursin("Erdos", k) && params[1] >= 1000) || (occursin("Bar", k) && params[2] >= 1000) || (occursin("Watts", k) && params[1] >= 1000) || (occursin("Config", k) && params[2] >= 1000)
            dist_graph = NetworkProcessing.compute_experimental_degree_distribution(k, graph, params)
            NetworkProcessing.compute_theoretical_degree_distribution(k, graph, params)
            savefig(dist_graph, "$save_pdf_dir/$name2save.png")
        end
        println("- model generated with params: $params")
    end
end