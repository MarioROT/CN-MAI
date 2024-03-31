module NetworkModels
    export erdos_renyi
    export barabasi_albert
    
    using Graphs
    using Distributions
    using Plots, GraphRecipes

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
            r1 = rand(1:10)
            r2 = rand(1:10)

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
end