function test_query(q, text)
    res = run(q)

    @fact res.query --> q
    @fact isempty(res.scores) --> false
    @fact isempty(res.matches) --> false

    # Get the raw docstring.
    doc = getdoc(res)

    @fact doc --> text
end

getdoc(res) = data(docs(first(first(reverse(sort([(a, b) for (a, b) in res.scores])))[2])))

facts("Query results.") do

    context("Functions.") do

        test_query(@query(f), "f")
        test_query(@query(g), "g")

        test_query(@query(f, 1), "f")
        test_query(@query(g, 1), "g")

        test_query(@query(A.f), "A.f")
        test_query(@query(A.g), "A.g")

        test_query(@query(A.f, 1), "A.f")
        test_query(@query(A.g, 1), "A.g")

        test_query(@query(A.B.f), "A.B.f")
        test_query(@query(A.B.g), "A.B.g")

        test_query(@query(A.B.f, 1), "A.B.f")
        test_query(@query(A.B.g, 1), "A.B.g")

    end

    context("Methods.") do

        test_query(@query(f()), "f/0")
        test_query(@query(g()), "g/0")

        test_query(@query(f(1)), "f/1")
        test_query(@query(g(1)), "g/1")

        test_query(@query(f(), 1), "f/0")
        test_query(@query(g(), 1), "g/0")

        test_query(@query(f(1), 1), "f/1")
        test_query(@query(g(1), 1), "g/1")

        test_query(@query(A.f()), "A.f/0")
        test_query(@query(A.g()), "A.g/0")

        test_query(@query(A.f(1)), "A.f/1")
        test_query(@query(A.g(1)), "A.g/1")

        test_query(@query(A.f(), 1), "A.f/0")
        test_query(@query(A.g(), 1), "A.g/0")

        test_query(@query(A.f(1), 1), "A.f/1")
        test_query(@query(A.g(1), 1), "A.g/1")

        test_query(@query(A.B.f()), "A.B.f/0")
        test_query(@query(A.B.g()), "A.B.g/0")

        test_query(@query(A.B.f(1)), "A.B.f/1")
        test_query(@query(A.B.g(1)), "A.B.g/1")

        test_query(@query(A.B.f(), 1), "A.B.f/0")
        test_query(@query(A.B.g(), 1), "A.B.g/0")

        test_query(@query(A.B.f(1), 1), "A.B.f/1")
        test_query(@query(A.B.g(1), 1), "A.B.g/1")

    end

    context("Macros.") do

        test_query(@query(@m), "@m")
        test_query(@query(@m(), 1), "@m")
        test_query(@query(A.@m), "A.@m")

        test_query(@query(A.@m(), 1), "A.@m")
        test_query(@query(A.B.@m), "A.B.@m")
        test_query(@query(A.B.@m(), 1), "A.B.@m")

    end

    context("Types.") do

        test_query(@query(T), "T")
        test_query(@query(A.T), "A.T")
        test_query(@query(A.B.T), "A.B.T")

        test_query(@query(T, 1), "T")
        test_query(@query(A.T, 1), "A.T")
        test_query(@query(A.B.T, 1), "A.B.T")

        test_query(@query(S), "S")
        test_query(@query(A.S), "A.S")
        test_query(@query(A.B.S), "A.B.S")

        test_query(@query(S, 1), "S")
        test_query(@query(A.S, 1), "A.S")
        test_query(@query(A.B.S, 1), "A.B.S")

    end

    context("Globals.") do

        test_query(@query(A.K), "A.K")
        test_query(@query(A.B.K), "A.B.K")

        test_query(@query(A.K, 1), "A.K")
        test_query(@query(A.B.K, 1), "A.B.K")

    end

    context("Partial signature matching.") do

        @fact getdoc(query(f, (Any,))) --> "f/1"
        @fact getdoc(query(g, (Any,))) --> "g/1"

        @fact getdoc(query(A.f, (Any,))) --> "A.f/1"
        @fact getdoc(query(A.g, (Any,))) --> "A.g/1"

        @fact getdoc(query(A.B.f, (Any,))) --> "A.B.f/1"
        @fact getdoc(query(A.B.g, (Any,))) --> "A.B.g/1"

    end

    context("Full text search.") do

        test_query(@query("A.f/0"), "A.f/0")
        test_query(@query("A.f/1"), "A.f/1")

        test_query(@query("A.g/0"), "A.g/0")
        test_query(@query("A.g/1"), "A.g/1")

        test_query(@query("A.B.f/0"), "A.B.f/0")
        test_query(@query("A.B.f/1"), "A.B.f/1")

        test_query(@query("A.B.g/0"), "A.B.g/0")
        test_query(@query("A.B.g/1"), "A.B.g/1")

    end

    context("REPL Help.") do

        Lexicon.help("")
        Lexicon.help("fft")
        Lexicon.help("1")
        Lexicon.help("foobar")
        Lexicon.help("foobar 1")
        Lexicon.help("Lexicon")
        Lexicon.help("Docile.@document")
        Lexicon.help("Docile.Entry")
        Lexicon.help("Docile.Entry 1")
        Lexicon.help("Docile.Entry(\"...\")")

        if VERSION < v"0.4-"
            Lexicon.help("...")
            Lexicon.help("do")
        end

    end
end
