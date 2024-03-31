using Distributions
using Graphs

function power_law_dist(gamma::Float64, max_degree::Int, n::Int)
    degrees = zeros(Int, n)
    for i in 1:n
        degree = round(Int, rand()^(-1/(gamma - 1)))
        degrees[i] = min(degree, max_degree)
    end
    return degrees
end


function configuration_model(distribution::String, n::Int, max::Int, param::Any)

    degrees = zeros(Int, n)
    if distribution == "poisson"
        k = param  # Poisson parameter
        poisson_distribution = Poisson(k)
        for i in 1:n
            degrees[i] = min(rand(poisson_distribution), max)
        end

    elseif distribution == "power-law"
        gamma = param  # Power-law exponent
        degrees = power_law_dist(param,max,n)
        
    else
        error("Unknown distribution. Supported distributions: 'poisson', 'power-law'.")
    end

    total_stubs = sum(degrees)
    # In case total degrees is odd, make it even
    if total_stubs % 2 != 0
        idx = rand(1:n)
        degrees[idx] += 1
        total_stubs += 1
    end
    # Create as many stubs as the degree of each node
    stubs = []
    for (node, degree) in enumerate(degrees)
        for _ in 1:degree
            push!(stubs, node)
        end
    end
    # Randomly order the stubs
    Random.shuffle!(stubs)
    graph = Graphs.SimpleGraph(n)

    while length(stubs) >= 2
        u = pop!(stubs)
        v = pop!(stubs)
        # Avoiding self-loops and multiple edges
        if u != v && !Graphs.has_edge(graph, u, v)
            Graphs.add_edge!(graph, u, v)
        end
    end
    return graph
end


# poisson_degrees = configuration_model("poisson", 100, 10, 4)

power_law_degrees = configuration_model("power-law", 100, 10, 2.7)

