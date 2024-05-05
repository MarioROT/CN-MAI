module DynamicSimulations
    export monte_carlo
    export all_combinations
    
    using Graphs
    using Random
    using DataStructures
    using Statistics
    using Setfield

    abstract type Model end

    struct SIS <: Model
        μ::Float64 
        β::Float64
        network::Graphs.SimpleGraphs.SimpleGraph{Int64}
        timeStep::Int64
        verticesState::Vector{Bool}
    end
    μ(s::SIS) = s.μ 
    β(s::SIS) = s.β
    network(s::SIS) = s.network
    timeStep(s::SIS) = s.timeStep
    verticesState(s::SIS) = s.verticesState

    function create_SIS(graph, μ::AbstractFloat, β::AbstractFloat, p::AbstractFloat)
        v = rand!(zeros(nv(graph)))
        verticesState = [i < p for i in v]
        return SIS(μ, β, graph, 0, verticesState)
    end

    function update_SIS(m::Model)
        m = @set m.timeStep += 1
        for vertex in vertices(m.network)
            if m.verticesState[vertex] == 1 && rand() < m.μ
                m = @set m.verticesState[vertex] = 0
            else
                for neighbor in neighbors(m.network, vertex)
                    if rand() < m.β
                        m = @set m.verticesState[vertex] = 1
                        break
                    end
                end    
            end
        end 
        return m
    end

    function monte_carlo(N_rep::Int64, T_max::Int64, T_trans::Int64, initParams::Dict{String,Any})
        ps_reps = []
        for rep in 1:N_rep
#             println("----- > Running simulation: $rep")
            sis = create_SIS(initParams["graph"], initParams["μ"], initParams["β"], initParams["p0"])
            ps_steps = []
            for step in 1:T_max
                sis = update_SIS(sis)
                if step < T_trans
                    push!(ps_steps, counter(sis.verticesState)[1]/size(sis.verticesState)[1])
                end
            end
            push!(ps_reps,mean(ps_steps))
        end
        return mean(ps_reps)
    end

    allcombinations(v...) = vec(collect(Iterators.product(v...)))
end