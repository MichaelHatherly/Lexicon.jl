facts("Query parsing.") do

    context("Functions.") do

        @fact @query(f) --> Query([f, :f], 0)
        @fact @query(g) --> Query([g, :g], 0)

        @fact @query(f, 1) --> Query([f, :f], 1)
        @fact @query(g, 1) --> Query([g, :g], 1)

        @fact @query(A.f) --> Query([A.f, :f], A, 0)
        @fact @query(A.g) --> Query([A.g, :g], A, 0)

        @fact @query(A.f, 1) --> Query([A.f, :f], A, 1)
        @fact @query(A.g, 1) --> Query([A.g, :g], A, 1)

        @fact @query(A.B.f) --> Query([A.B.f, :f], A.B, 0)
        @fact @query(A.B.g) --> Query([A.B.g, :g], A.B, 0)

        @fact @query(A.B.f, 1) --> Query([A.B.f, :f], A.B, 1)
        @fact @query(A.B.g, 1) --> Query([A.B.g, :g], A.B, 1)

    end

    context("Methods.") do

        @fact @query(f()) --> Query([@which(f())], 0)
        @fact @query(g()) --> Query([@which(g())], 0)

        @fact @query(f(1)) --> Query([@which(f(1))], 0)
        @fact @query(g(1)) --> Query([@which(g(1))], 0)

        @fact @query(f(), 1) --> Query([@which(f())], 1)
        @fact @query(g(), 1) --> Query([@which(g())], 1)

        @fact @query(f(1), 1) --> Query([@which(f(1))], 1)
        @fact @query(g(1), 1) --> Query([@which(g(1))], 1)


        @fact @query(A.f()) --> Query([@which(A.f())], A, 0)
        @fact @query(A.g()) --> Query([@which(A.g())], A, 0)

        @fact @query(A.f(1)) --> Query([@which(A.f(1))], A, 0)
        @fact @query(A.g(1)) --> Query([@which(A.g(1))], A, 0)

        @fact @query(A.f(), 1) --> Query([@which(A.f())], A, 1)
        @fact @query(A.g(), 1) --> Query([@which(A.g())], A, 1)

        @fact @query(A.f(1), 1) --> Query([@which(A.f(1))], A, 1)
        @fact @query(A.g(1), 1) --> Query([@which(A.g(1))], A, 1)


        @fact @query(A.B.f()) --> Query([@which(A.B.f())], A.B, 0)
        @fact @query(A.B.g()) --> Query([@which(A.B.g())], A.B, 0)

        @fact @query(A.B.f(1)) --> Query([@which(A.B.f(1))], A.B, 0)
        @fact @query(A.B.g(1)) --> Query([@which(A.B.g(1))], A.B, 0)

        @fact @query(A.B.f(), 1) --> Query([@which(A.B.f())], A.B, 1)
        @fact @query(A.B.g(), 1) --> Query([@which(A.B.g())], A.B, 1)

        @fact @query(A.B.f(1), 1) --> Query([@which(A.B.f(1))], A.B, 1)
        @fact @query(A.B.g(1), 1) --> Query([@which(A.B.g(1))], A.B, 1)

    end

    context("Macros.") do

        @fact @query(@m)      --> Query([getfield(LexiconTests, symbol("@m"))], 0)
        @fact @query(@m(), 1) --> Query([getfield(LexiconTests, symbol("@m"))], 1)

        @fact @query(A.@m)      --> Query([getfield(A, symbol("@m"))], A, 0)
        @fact @query(A.@m(), 1) --> Query([getfield(A, symbol("@m"))], A, 1)

        @fact @query(A.B.@m)      --> Query([getfield(A.B, symbol("@m"))], A.B, 0)
        @fact @query(A.B.@m(), 1) --> Query([getfield(A.B, symbol("@m"))], A.B, 1)

    end

    context("Types.") do

        @fact @query(T)     --> Query([T, :T], 0)
        @fact @query(A.T)   --> Query([A.T, :T], A, 0)
        @fact @query(A.B.T) --> Query([A.B.T, :T], A.B, 0)

        @fact @query(T, 1)     --> Query([T, :T], 1)
        @fact @query(A.T, 1)   --> Query([A.T, :T], A, 1)
        @fact @query(A.B.T, 1) --> Query([A.B.T, :T], A.B, 1)

        @fact @query(S)     --> Query([S, :S], 0)
        @fact @query(A.S)   --> Query([A.S, :S], A, 0)
        @fact @query(A.B.S) --> Query([A.B.S, :S], A.B, 0)

        @fact @query(S, 1)     --> Query([S, :S], 1)
        @fact @query(A.S, 1)   --> Query([A.S, :S], A, 1)
        @fact @query(A.B.S, 1) --> Query([A.B.S, :S], A.B, 1)

    end

    context("Globals.") do

        @fact @query(K)     --> Query([K, :K], 0)
        @fact @query(A.K)   --> Query([A.K, :K], A, 0)
        @fact @query(A.B.K) --> Query([A.B.K, :K], A.B, 0)

        @fact @query(K, 1)     --> Query([K, :K], 1)
        @fact @query(A.K, 1)   --> Query([A.K, :K], A, 1)
        @fact @query(A.B.K, 1) --> Query([A.B.K, :K], A.B, 1)

    end
end
