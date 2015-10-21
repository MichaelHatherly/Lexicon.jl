module LexiconTests

using Lexicon.Docile
@document

using Lexicon.Docile.Interface, Lexicon, FactCheck

import Lexicon: Query

include(joinpath(dirname(@__FILE__), "testcases.jl"))
Lexicon.Docile.Cache.register_module(joinpath(dirname(@__FILE__), "testcases.jl"))

import .TestCases: f, g, A, T, @m, K, S

include("facts/query-parsing.jl")
include("facts/querying-results.jl")
include("facts/rendering.jl")
include("facts/filtering.jl")

end
