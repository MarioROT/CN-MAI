include("../Assignment 1/NetworkProcessing.jl")
include("../Assignment 2/NetworkModels.jl")
include("DynamicSimulations.jl")

using DataStructures
using CSV
using Plots

baseDir = "Networks/"
resultsDir = "Results/"
μs = [0.1,0.5,0.9]
βs = LinRange(0,1,51)
networks = readdir(baseDir)
net_results = Dict{Int64, Vector}()
print("------------- Processing Networks -------------")
for (i,network) in enumerate(networks)
    print("\n - > $network")
    graph, edge_weights, vertex_labels  = NetworkProcessing.read_network(baseDir * "$network")
    temp_res = Dict{AbstractFloat, Dict{String, Vector{Float64}}}()
    for (j,comb) in enumerate(DynamicSimulations.allcombinations(βs, μs))
#         println("--- > Running combination: $j - $comb")
        initParams = Dict("graph"=>graph,"μ"=>comb[2], "β"=>comb[1], "p0"=>0.2)
        p = DynamicSimulations.monte_carlo(100, 1000, 900, initParams)
        if j %51 == 1
            temp_res[comb[2]] = Dict("p"=>[p], "β"=>[comb[1]])
        else
            append!(temp_res[comb[2]]["p"], [p])
            append!(temp_res[comb[2]]["β"], [comb[1]])
        end
        net_results[i*j] = [network, comb[2], comb[1], p]
    end
    for (i, (μ, dict)) in enumerate(temp_res)
        if i == 1
            plot(dict["β"],dict["p"], marker=:cirlce, label=μ, title=network)
        else
            plot!(dict["β"],dict["p"], marker=:cirlce, label=μ)
        end
    end
    savefig(resultsDir * "/Figs/$network.png")
end

df = NetworkProcessing.construct_df(net_results, ["network","μ","β","p"])

CSV.write(resultsDir * "/Reports/Exercise_Results.csv", df)