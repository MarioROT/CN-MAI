module NetworkModels
    export erdos_renyi
    export barabasi_albert
    export small_world
    export configuration_model
    
    using Graphs
    using GraphIO
    using Distributions
    using Plots, GraphRecipes
    using Random

    function erdos_renyi(n::Int,k::Int)
        g = SimpleGraph(n)
        if k < 0
            k = 0
            println("The value of K must be greater to or equal than 0. Using K=0.")
        elseif k > (n*(n-1))/2
            k = Integer((n*(n-1))/2)
            println("The value of K must be equal to or lower than $k. Using K=$k.")
        end

        connections = Dict(i => Vector{Int}() for i in 1:n)
        connected = 0

        while connected < k 
            r1 = rand(1:n)
            r2 = rand(1:n)

            if r1 != r2 && !(r1 in connections[r2]) && !(r2 in connections[r1])
                add_edge!(g, r1, r2)
                append!( connections[r1], r2 )
                append!( connections[r2], r1 )
                connected += 1
            end
        end
        return g
    end

    function erdos_renyi(n::Int,p::Float64, p_v=1::Int)
        g = SimpleGraph(n)
        if p <= 0.0
            println("The value of K must be between 0 and 1. Using p=$p.")
            return g
        elseif p > 1.0
            p = 1.0
            println("The value of K must be between 0 and 1. Using p=$p.")
        end
        if p_v == 1 
            for i in 1:n
                for j in i+1:n
                    r = rand()
                    if r <= p
                        add_edge!(g, i, j)
                    end
                end
            end
            return g
        else
            binomialDistribution = Binomial(n*(n-1)/2,p)
            k = Integer(rand(binomialDistribution, 1)[1])
            print
            return erdos_renyi(n,k)
        end
    end

    function barabasi_albert(m_0::Int, N::Int, m::Int, init = 0.4::Any)
        m <= m_0 <= N ? nothing : throw(AssertionError("Parameter values must satisfy the following rule: m <= m_0 <= N")) 
        if init <= 1.0 && init isa AbstractFloat
            g = erdos_renyi(m_0, init)
        else
            g = path_graph(m_0)
    #         g = SimpleGraph(10)
    #         for i in 1:(nv(g)-1)
    #             add_edge!(g, i, i+1)
    #         end
    #         graphplot(g, curves=false)
        end

        for i in m_0+1:N
            if add_vertex!(g)
                degrees = degree(g)
                total_degree = sum(degrees)  
                probabilities = degrees / total_degree  
                distribution = Categorical(probabilities)
                sampled_vertices = rand(distribution, m)

                for j in sampled_vertices
                    add_edge!(g, i, j)
                end
            end
        end
        return g
    end

    function small_world(n::Int, k::Int, p::Float64)
        g = Graphs.SimpleGraph(n)
        neighbor=div(k,2)
      
        #We create a ring network
        for node in 1:n
          for k in 1:neighbor
            k1=node+k
            k2=node+n-k
      
            if k1>n
              Graphs.add_edge!(g, node, k1%n)
            else
              Graphs.add_edge!(g, node, k1)
            end
      
            if k2>n
              Graphs.add_edge!(g, node, k2%n)
            else
              Graphs.add_edge!(g, node, k2)
            end
          end
        end
      
        #We change randomly edge connections to add higher clustering
        for edge in Graphs.edges(g)
          if rand() < p
      
            u, v = Graphs.src(edge), Graphs.dst(edge)
            target = rand(1:n)
      
            #Not self loops or previous or multi-edge allowed
            while target == u || Graphs.has_edge(g, u, target)
                target = rand(1:n)
            end
      
            Graphs.rem_edge!(g, edge)
            Graphs.add_edge!(g, u, target)
          end
        end
        return g
      end

    function configuration_model(degree_distribution::Vector{Int})
        num_nodes = length(degree_distribution)
        total_stubs = sum(degree_distribution)
        # In case total degrees is odd, make it even
        if total_stubs % 2 != 0
            idx = rand(1:num_nodes)
            degree_distribution[idx] += 1
            total_stubs += 1
        end
        # Create as many stubs as the degree of each node
        stubs = []
        for (node, degree) in enumerate(degree_distribution)
            for _ in 1:degree
                push!(stubs, node)
            end
        end
        # Randomly order the stubs
        Random.shuffle!(stubs)
        graph = Graphs.SimpleGraph(num_nodes)

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
end