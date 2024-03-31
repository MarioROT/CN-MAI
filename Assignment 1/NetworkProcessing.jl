module NetworkProcessing

    export network_num_descriptors
    export nodes_num_descriptors
    export construct_df
    export degree_pdf

    using Graphs, Graphs.Experimental.ShortestPaths
    using GraphIO

    using GraphIO.NET
    using Statistics
    using DataFrames
    using Plots
    using Distributions

    function parse_vertices_labels(filepath)
        vertex_labels = Dict{Int, AbstractString}()
        local vertex_count = 0
        open(filepath, "r") do file
            for line in eachline(file)
                line = strip(line)
                if startswith(line, "*Vertices")
                    # Extract the number of vertices
                    vertex_count = parse(Int, split(line)[2])
                elseif startswith(line, "*Edges") || startswith(line, "*Arcs")
                    break
                elseif !isempty(line) && !startswith(line, "%") && vertex_count > 0
                    # Parsing vertex definitions

                    parts = split(line, limit=4)
                    vertex_id = parse(Int, parts[1])
                    vertex_label = replace(parts[2], r"^\"|\"$" => "")
                    vertex_labels[vertex_id] = vertex_label
                end
            end
        end
        return vertex_labels
    end

    function read_network(file_path)
        graph = loadgraph(file_path, "graph_key", NETFormat())
    
        vertex_labels = parse_vertices_labels(file_path)

        edge_weights = Dict{Tuple{Int,Int}, Float64}()
        open(file_path, "r") do file
            reading_edges = false
            for line in eachline(file)
                if occursin("*Edges", line)
                    reading_edges = true
                elseif reading_edges
                    edge_data = split(line)
                    if length(edge_data) >= 3
                        src, dst, weight = parse(Int, edge_data[1]), parse(Int, edge_data[2]), parse(Float64, edge_data[3])
                        edge_weights[(src, dst)] = weight
                        # Assuming you add edges to your graph here
                        add_edge!(graph, src, dst)  # Add the edge to the graph if not already added
                    end
                end
            end
        end
        return graph, edge_weights, vertex_labels
    end


    function network_num_descriptors(graph, verbose = true)
        # Number of nodes and edges
        num_nodes = nv(graph)
        num_edges = ne(graph)

        # Degrees
        degrees = degree(graph)
        min_degree = minimum(degrees)
        max_degree = maximum(degrees)
        avg_degree = mean(degrees)

        # Average clustering coefficient 
        avg_clustering_coefficient = sum(local_clustering_coefficient(graph, vertices(graph)))/nv(graph)

        # Assortativity 
        assort = assortativity(graph)

        # Average path length and Diameter
        # For a large graph, this might be computationally expensive
        avg_path_length = sum(shortest_paths(graph).dists)/(num_nodes*(num_nodes-1))
        diam = Graphs.diameter(graph)  # Same adjustment as above

        if verbose
            # Printing the results
            println("Number of nodes: $num_nodes")
            println("Number of edges: $num_edges")
            println("Degree -- Min: $min_degree, Max: $max_degree, Avg: $avg_degree")
            println("Average Clustering Coefficient: $avg_clustering_coefficient")
            println("Assortativity: $assort")
            println("Average Path Length: $avg_path_length")
            println("Diameter: $diam")
        end

        return [isa(i, AbstractFloat) ? round(i, digits=4) : i for i in [num_nodes, num_edges, min_degree, max_degree, avg_degree, avg_clustering_coefficient, assort, avg_path_length, diam]]
    end

    function construct_df(data_dict, col_names = [])
        # Initialize an empty DataFrame with appropriate column names
        if isempty(col_names)
            col_names = ["Col$(i)" for i in 1:length(first(values(data_dict)))]
        end

        col_names_with_key = ["Index"; col_names]

        # Initialize an empty DataFrame with the updated column names
        df = DataFrame(; (Symbol(col_name) => Any[] for col_name in col_names_with_key)...)

        # Sort the dictionary by keys to maintain the order
        sorted_keys = sort(collect(keys(data_dict)))

        # Populate the DataFrame, including the key as the first column in each row
        for key in sorted_keys
            row_data = [key; data_dict[key]]
            push!(df, row_data)
        end

        return df
    end

    function compute_strength(edge_weights, mode="undirected")
        weights_count = Dict{Int, Float64}()
        if mode == "undirected"
            for (key,value) in edge_weights
                for v in key
                    if haskey(weights_count, v)
                        weights_count[v] += value
                    else
                        weights_count[v] = value
                    end
                end
            end
        elseif mode == "directed"
            for (key,value) in edge_weights
                v = key[1]
                if haskey(weights_count, v)
                    weights_count[v] += value
                else
                    weights_count[v] = value
                end
            end
        end
        return weights_count
    end


    function compute_max_path_length_per_node(g::AbstractGraph)
        max_lengths = Dict{Int,Int}()
        for src in vertices(g)
            # Initialize a dictionary to hold distances, defaulting to -1 (indicating unreachable)
            distances = fill(-1, nv(g))
            distances[src] = 0  # Distance to self is 0

            # BFS
            bfs_queue = [src]
            while !isempty(bfs_queue)
                current_vertex = popfirst!(bfs_queue)
                for neighbor in neighbors(g, current_vertex)
                    if distances[neighbor] == -1  # If not visited
                        distances[neighbor] = distances[current_vertex] + 1
                        push!(bfs_queue, neighbor)
                    end
                end
            end

            # Find the maximum distance from src to any other node
            max_distance = maximum(distances)
            max_lengths[src] = max_distance
        end
        return max_lengths
    end



    function nodes_num_descriptors(graph, edge_weights, vertex_labels = false, verbose = false)
        num_nodes = nv(graph)
        node_descriptors = Dict{Any, Vector}()
        degrees = degree(graph)
        strenghts = compute_strength(edge_weights)
        aspls = shortest_paths(graph).dists
#         lpls = maximum(collect(adjacency_matrix(graph)); dims = 2)
        lpls = compute_max_path_length_per_node(graph)
        b_centralities = betweenness_centrality(graph) 
        e_centralities = eigenvector_centrality(graph)
        pageranks = pagerank(graph)
        for i in vertices(graph)
            deg = degrees[i]
            stren = strenghts[i]
            aspl = sum(aspls[i,:])/(num_nodes-1)
            lspl = lpls[i]
            cl_cf = local_clustering_coefficient(graph, i)
            bc = b_centralities[i] 
            ec = e_centralities[i]
            pr = pageranks[i]
        
            if vertex_labels != false
                node_descriptors[vertex_labels[i]] = [isa(i, AbstractFloat) ? round(i, digits=8) : i for i in [deg,stren, aspl, lspl, cl_cf, bc, ec, pr]]
            else
                node_descriptors[i] = [isa(i, AbstractFloat) ? round(i, digits=8) : i for i in [deg,stren, aspl, lspl, cl_cf, bc, ec, pr]]
            end
        end
    
        node_descriptors_df = construct_df(node_descriptors, ["Degree", "Strength", "ASPL", "LPL", "Clust Coeff", "Betweeness", "Eigenvector", "PageRank"])
    
        if verbose
            println(node_descriptors_df)
        end
        return node_descriptors_df
    end
  
    #Fucntion to select the number of decimals displayed in the charts
    function custom_xformatter(x)
        return string(round(x, digits=3))  
    end

    function custom_xformatter(x)
      return string(round(x, digits=3))  # Round to 1 decimal place
    end

    # Function to calculate the degree probability distribution function and the complimentary cummulative distribution function
    function degree_pdf(graph, num_bins::Int=10, log_scale::Bool=false, CCDF::Bool=false)

        degree_counts = Graphs.degree_histogram(graph)

        # Calculate probabilities
        num_nodes = nv(graph)
        pdf =sort( Dict(degree => count / num_nodes for (degree, count) in degree_counts))

        degrees = collect(keys(pdf))
        probabilities = collect(values(pdf))


        if log_scale

            # Find 𝑘min = min(𝑘) and 𝑘max = max(𝑘) to change to log-scale
            k_min = minimum(degree(graph))
            k_max = maximum(degree(graph))
            log_data = log.(degree(graph))
            bin_edges = range(log(k_min), stop=log(k_max + 1), length=num_bins+1)
            total_elements = length(log_data)

            bin_counts = zeros(Int, length(bin_edges))

            for element in log_data
                # Find the index of the bin the element belongs to
                bin_index = findfirst(x -> x >= element, bin_edges[2:length(bin_counts)])
                bin_counts[bin_index] += 1
            end

            bin_counts=bin_counts[1:length(bin_counts)-1]

            probabilities=bin_counts/total_elements

            # Calculate CCDF
            if CCDF
                ccdf_values = 1.0 .- cumsum(probabilities)
                plot=bar(bin_edges, ccdf_values,  xlabel="log(K)", ylabel="Comp. Cum. Log(Pk)", title="CCDF Log-Log Histogram",xticks=bin_edges, legend=false,bar_edges=false,xrotation=45, xformatter=custom_xformatter, yscale=:log10 )
            else
                plot=bar(bin_edges, probabilities,  xlabel="log(K)", ylabel="Log(Pk)", title="Log-Log PDF Histogram",xticks=bin_edges, legend=false,bar_edges=false,xrotation=45, xformatter=custom_xformatter, yscale=:log10 )

            end

        else

            if CCDF
                plt=histogram(degrees, weights=probabilities, bins=num_bins)

                deg_bins=plt[1][2][:x]
                prob_bins=plt[1][2][:y]
                
                # Calculate CCDF
                cum_prob_bins=1 .- cumsum(prob_bins)
                plot=bar(deg_bins,cum_prob_bins, xlabel="Degree (k)", ylabel="Comp. Cum. P(k)", title=" CCDF Histogram",xticks=deg_bins, legend=false,bar_edges=false,xrotation=45, xformatter=custom_xformatter )
            
            else
                plot = histogram(degrees, weights=probabilities, xlabel="Degree (k)", ylabel="Probability (P(K))", title="PDF Histogram" ,legend=false, bins=num_bins, xformatter=custom_xformatter )
            end

        end
        
        return plot
    end

    # Function to save a graph to .net format
    function save_network(g::AbstractGraph, filename::String, file_type="net"::String)
        n = nv(g) 
        edges = Graphs.edges(g) 

        open(filename, "w") do io
            # Writing the vertices
            write(io, "*Vertices $n\n")
            for i in 1:n
                write(io, "$i \"Node $i\"\n")
            end

            # Writing the edges
            write(io, "*Edges\n")
            for e in edges
                write(io, "$(src(e)) $(dst(e))\n") 
            end
        end
    end

    #Creates a power-law distribution of data
    function power_law_dist(gamma::Float64, max_degree::Int, n::Int)
        degrees = zeros(Int, n)
        for i in 1:n
            degree = round(Int, rand()^(-1/(gamma - 1)))
            degrees[i] = min(degree, max_degree)
        end
        return degrees
    end

    # compute theoretical probability distribution
    function compute_theoretical_degree_distribution(Mtype, graph, params)
        if Mtype in ["Erdos-Renyi/NP", "Erdos-Renyi/NK"]
            maxD = maximum(degree(graph))
            minD = minimum(degree(graph))
            k_values = minD:maxD+1
            N, p = params
            if Mtype == "Erdos-Renyi/NK"
                p = 2*p/(N*(N-1))
            end
            degree_distribution = Binomial(N-1, p)
            theoretical_probabilities = [pdf(degree_distribution, k) for k in k_values]
            return plot!(k_values, theoretical_probabilities, line=(:red, 2), marker=:none)
        elseif Mtype in ["Barabasi-Albert"]
            degrees = degree(graph)
            m_0, N, m = params 
            k_min = m
            k_max = maximum(degrees) 
            k_values_theo = k_min:k_max
            p_k_theo = [2 * m^2 / k^3 for k in k_values_theo]
        
            return plot!(k_values_theo, p_k_theo, xscale=:log10, yscale=:log10, line=(:solid, :red), label="Theoretical")
        elseif Mtype in ["Watts-Strogatz"]
            return 1
        elseif Mtype in ["Configuration-Model"]
            typeP, n, maxi, param = params
            if typeP == "poisson"
                poisson_distribution = Poisson(param)
                vals = zeros(Int, n)
                for i in 1:n
                    vals[i] = min(rand(poisson_distribution), maxi)
                end
            else
                vals = power_law_dist(param, maxi, n)
            end

            degree_distribution = Dict{Int, Number}()
            for d in vals
                degree_distribution[d] = get(degree_distribution, d, 0) + 1
            end

            total = sum(values(degree_distribution))
            for (k, v) in degree_distribution
                degree_distribution[k] = v / total
            end
            sorted_degrees = sort(collect(keys(degree_distribution)))
            probabilities = [degree_distribution[k] for k in sorted_degrees]
            return plot!(sorted_degrees, probabilities, line=(:red, 2), marker=:none)
        end
    end
    # Experimental degree distribution
    function compute_experimental_degree_distribution(Mtype, graph, params)
        if Mtype in ["Erdos-Renyi/NP", "Erdos-Renyi/NK", "Watts-Strogatz", "Configuration-Model"]
            maxD = maximum(degree(graph))
            return degree_pdf(graph, maxD+1)
        elseif Mtype in ["Barabasi-Albert"]
            degrees = degree(graph)
            degree_counts = Dict{Int, Int}()
            for degree in degrees
                degree_counts[degree] = get(degree_counts, degree, 0) + 1
            end
            total_nodes = length(degrees)
            experimental_distribution = Dict{Int, Float64}()
            for (degree, count) in degree_counts
                experimental_distribution[degree] = count / total_nodes
            end

            # Prepare experimental data for plotting
            k_values_exp = sort(collect(keys(experimental_distribution)))
            p_k_exp = [experimental_distribution[k] for k in k_values_exp]

            # Plotting both distributions on a log-log scale
            return plot(k_values_exp, p_k_exp, xscale=:log10, yscale=:log10, line=(:dot, :blue), marker=(:circle, :blue), label="Experimental")
        end 
    end
end