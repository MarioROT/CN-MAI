module NetworkProcessing

    export network_num_descriptors
    export nodes_num_descriptors
    export construct_df

    using Graphs, Graphs.Experimental.ShortestPaths
    using GraphIO

    using GraphIO.NET
    using Statistics
    using DataFrames

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
end