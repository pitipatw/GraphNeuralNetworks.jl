@testset "GlobalPool" begin
    p = GlobalPool(+)
    n = 10
    chin = 6
    X = rand(Float32, 6, n)
    g = GNNGraph(random_regular_graph(n, 4), ndata = X, graph_type = GRAPH_T)
    u = p(g, X)
    @test u ≈ sum(X, dims = 2)

    ng = 3
    g = Flux.batch([GNNGraph(random_regular_graph(n, 4),
                                ndata = rand(Float32, chin, n),
                                graph_type = GRAPH_T)
                    for i in 1:ng])
    u = p(g, g.ndata.x)
    @test size(u) == (chin, ng)
    @test u[:, [1]] ≈ sum(g.ndata.x[:, 1:n], dims = 2)
    @test p(g).gdata.u == u

    test_layer(p, g, rtol = 1e-5, exclude_grad_fields = [:aggr], outtype = :graph)
end

@testset "GlobalAttentionPool" begin
    n = 10
    chin = 6
    chout = 5
    ng = 3

    fgate = Dense(chin, 1)
    ffeat = Dense(chin, chout)
    p = GlobalAttentionPool(fgate, ffeat)
    @test length(Flux.params(p)) == 4

    g = Flux.batch([GNNGraph(random_regular_graph(n, 4),
                                ndata = rand(Float32, chin, n),
                                graph_type = GRAPH_T)
                    for i in 1:ng])

    test_layer(p, g, rtol = 1e-5, outtype = :graph, outsize = (chout, ng))
end

@testset "TopKPool" begin
    N = 10
    k, in_channel = 4, 7
    X = rand(in_channel, N)
    for T in [Bool, Float64]
        adj = rand(T, N, N)
        p = TopKPool(adj, k, in_channel)
        @test eltype(p.p) === Float32
        @test size(p.p) == (in_channel,)
        @test eltype(p.Ã) === T
        @test size(p.Ã) == (k, k)
        y = p(X)
        @test size(y) == (in_channel, k)
    end
end

@testset "topk_index" begin
    X = [8, 7, 6, 5, 4, 3, 2, 1]
    @test topk_index(X, 4) == [1, 2, 3, 4]
    @test topk_index(X', 4) == [1, 2, 3, 4]
end
