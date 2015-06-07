import Docile

import Lexicon.Queries:

    @query_str,
    runquery,

    Query,

    Text,
    Object,
    Metadata,

    ArgumentTypes,
    ReturnTypes,

    And,
    Or,
    Not,

    MatchAnything

function check(query, term, index)
    @fact query.term  => term
    @fact query.index => index
    nothing
end

facts("Query generation.") do

    context("Indexes.") do

        check(query"facts",
              Object(:facts, facts), 0)
        check(query"\"...\"",
              Text("..."), 0)

        check(query"facts 1",
              Object(:facts, facts), 1)
        check(query"\"...\" 1",
              Text("..."), 1)

    end

    context("Objects.") do

        check(query"facts",
              Object(:facts, facts), 0)
        check(query"FactCheck.facts",
              Object(:facts, FactCheck.facts), 0)

        λ = getfield(FactCheck, symbol("@fact"))

        check(query"@fact",
              Object(symbol("@fact"), λ), 0)
        check(query"FactCheck.@fact",
              Object(symbol("@fact"), λ), 0)

        check(query"@fact() 1",
              Object(symbol("@fact"), λ), 1)
        check(query"FactCheck.@fact() 1",
              Object(symbol("@fact"), λ), 1)

        check(query"FactCheck",
              Object(:FactCheck, FactCheck), 0)
        check(query"MatchAnything",
              Object(:MatchAnything, Lexicon.Queries.MatchAnything), 0)

    end

    context("Signatures.") do

        check(query"::Bool",
              ReturnTypes(Bool), 0)
        check(query"::(Int, Any)",
              ReturnTypes(@compat(Tuple{Int, Any})), 0)

        check(query"::Bool 1",
              ReturnTypes(Bool), 1)
        check(query"::(Int, Any) 1",
              ReturnTypes(@compat(Tuple{Int, Any})), 1)

        check(query"(Int,)",
              ArgumentTypes(@compat(Tuple{Int})), 0)
        check(query"(Int, Bool)",
              ArgumentTypes(@compat(Tuple{Int, Bool})), 0)

        check(query"(Int,) 1",
              ArgumentTypes(@compat(Tuple{Int})), 1)
        check(query"(Int, Bool) 1",
              ArgumentTypes(@compat(Tuple{Int, Bool})), 1)

        check(query"(Int,)::Bool",
              And(ArgumentTypes(@compat(Tuple{Int})), ReturnTypes(Bool)), 0)
        check(query"(Int, Any)::Bool",
              And(ArgumentTypes(@compat(Tuple{Int, Any})), ReturnTypes(Bool)), 0)
        check(query"(Int,)::(Bool, ASCIIString)",
              And(ArgumentTypes(@compat(Tuple{Int})),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 0)
        check(query"(Int, Float64)::(Bool, ASCIIString)",
              And(ArgumentTypes(@compat(Tuple{Int, Float64})),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 0)

        check(query"(Int,)::Bool 1",
              And(ArgumentTypes(@compat(Tuple{Int})), ReturnTypes(Bool)), 1)
        check(query"(Int, Any)::Bool 1",
              And(ArgumentTypes(@compat(Tuple{Int, Any})), ReturnTypes(Bool)), 1)
        check(query"(Int,)::(Bool, ASCIIString) 1",
              And(ArgumentTypes(@compat(Tuple{Int})),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 1)
        check(query"(Int, Float64)::(Bool, ASCIIString) 1",
              And(ArgumentTypes(@compat(Tuple{Int, Float64})),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 1)

        check(query"facts(Int,)::Bool",
              And(And(Object(:facts, facts),
                      ArgumentTypes(@compat(Tuple{Int}))),
                  ReturnTypes(Bool)), 0)
        check(query"facts(Int, Any)::Bool",
              And(And(Object(:facts, facts),
                      ArgumentTypes(@compat(Tuple{Int, Any}))),
                  ReturnTypes(Bool)), 0)
        check(query"FactCheck.facts(Int,)::(Bool, ASCIIString)",
              And(And(Object(:facts, facts),
                      ArgumentTypes(@compat(Tuple{Int}))),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 0)
        check(query"FactCheck.facts(Int, Float64)::(Bool, ASCIIString)",
              And(And(Object(:facts, facts),
                      ArgumentTypes(@compat(Tuple{Int, Float64}))),
                  ReturnTypes(@compat(Tuple{Bool, ASCIIString}))), 0)

    end

    context("Text.") do

        check(query"\"\"", Text(""), 0)
        check(query"\"\" 1", Text(""), 1)

        check(query"\"...\"", Text("..."), 0)
        check(query"\"...\" 1", Text("..."), 1)

    end

    context("Metadata.") do

        check(query"[a = 1]", Metadata([(:a, 1)]), 0)
        check(query"[a = 1] 1", Metadata([(:a, 1)]), 1)

        check(query"[a, b, c]", Metadata(
                  Any[(:a, MatchAnything()),
                      (:b, MatchAnything()),
                      (:c, MatchAnything())]
                  ), 0)
        check(query"[a = 1, b, c = 3]", Metadata(
                  Any[(:a, 1),
                      (:b, MatchAnything()),
                      (:c, 3)]
                  ), 0)
        check(query"[a, b, c = 3]", Metadata(
                  Any[(:a, MatchAnything()),
                      (:b, MatchAnything()),
                      (:c, 3)]
                  ), 0)
        check(query"[a = 1, b = 2, c]", Metadata(
                  Any[(:a, 1),
                      (:b, 2),
                      (:c, MatchAnything())]
                  ), 0)
        check(query"[a = 1, b = 2, c = 3]", Metadata(
                  Any[(:a, 1), (:b, 2), (:c, 3)]), 0)

    end

    context("Logic.") do

        check(query"facts & context",
              And(Object(:facts, facts),
                  Object(:context, context)), 0)

        check(query"facts | context",
              Or(Object(:facts, facts),
                 Object(:context, context)), 0)

        check(query"facts & !context",
              And(Object(:facts, facts),
                  Not(Object(:context, context))), 0)

        check(query"!facts | context",
              Or(Not(Object(:facts, facts)),
                 Object(:context, context)), 0)

        check(query"FactCheck.facts & FactCheck.context",
              And(Object(:facts, facts),
                  Object(:context, context)), 0)

        check(query"FactCheck.facts | FactCheck.context",
              Or(Object(:facts, facts),
                 Object(:context, context)), 0)

        check(query"FactCheck.facts & !FactCheck.context",
              And(Object(:facts, facts),
                  Not(Object(:context, context))), 0)

        check(query"!FactCheck.facts | FactCheck.context",
              Or(Not(Object(:facts, facts)),
                 Object(:context, context)), 0)

        λ1 = getfield(Base, symbol("@time"))
        λ2 = getfield(Base, symbol("@inbounds"))
        λ3 = getfield(Base, symbol("@simd"))
        λ4 = getfield(FactCheck, symbol("@fact"))

        check(query"@time() & [a = 1]",
              And(Object(symbol("@time"), λ1),
                  Metadata(Any[(:a, 1)])), 0)

        check(query"@inbounds() | @simd()",
              Or(Object(symbol("@inbounds"), λ2),
                 Object(symbol("@simd"), λ3)), 0)

        check(query"Base.@time() & [a = 1]",
              And(Object(symbol("@time"), λ1),
                  Metadata(Any[(:a, 1)])), 0)

        check(query"Base.@inbounds() | Base.@simd()",
              Or(Object(symbol("@inbounds"), λ2),
                 Object(symbol("@simd"), λ3)), 0)

        check(query"!@inbounds() & !Base.@simd()",
              And(Not(Object(symbol("@inbounds"), λ2)),
                  Not(Object(symbol("@simd"), λ3))), 0)

        check(query"facts & context & @fact()",
              And(And(Object(:facts, facts),
                      Object(:context, context)),
                  Object(symbol("@fact"), λ4)), 0)

        check(query"facts | @inbounds() & !context | @fact()",
              Or(Or(Object(:facts, facts),
                    And(Object(symbol("@inbounds"), λ2),
                        Not(Object(:context, context)))),
                 Object(symbol("@fact"), λ4)), 0)

        check(query"\"facts\" & \"context\" & !\"foobar\"",
              And(And(Text("facts"),
                      Text("context")),
                  Not(Text("foobar"))), 0)

        check(query"[a, b, c, d] & \"context\" & !\"foobar\"",
              And(And(Metadata(
                          Any[(:a, MatchAnything()),
                              (:b, MatchAnything()),
                              (:c, MatchAnything()),
                              (:d, MatchAnything())]),
                      Text("context")),
                  Not(Text("foobar"))), 0)

    end

end

facts("Running queries.") do

    # TODO: test returned values.

    context("Objects.") do
        runquery(query"Docile")
        runquery(query"Docile.Formats.metamacro")
        runquery(query"Docile.Collector.PackageData")
        runquery(query"@query_str")
        runquery(query"Lexicon.Queries.@query_str")
    end

    context("Text.") do
        runquery(query"\"...\"")
        runquery(query"\"\"")
    end

    context("Metadata.") do
        runquery(query"[a]")
        runquery(query"[a = 1]")
        runquery(query"[category = :function]")
    end

    context("Signatures.") do
        runquery(query"(Any,)")
        runquery(query"::Any")
        runquery(query"(Any, Any)::(Int,)")
        runquery(query"facts(Int)::Int")
        runquery(query"Lexicon.Queries.build(AbstractString)")
    end

    context("Logic.") do
        runquery(query"Docile & \"...\" | [a] & (Any,)")
        runquery(query"Docile.Formats.metamacro | \"\" & [a = 1] | ::Any")
        runquery(query"Docile.Collector.PackageData & [category = :function]")
        runquery(query"!@query_str() | (Any, Any)::(Int,) | facts(Int)::Int")
        runquery(query"Lexicon.Queries.@query_str() & Lexicon.Queries.build(AbstractString)")
    end

end
