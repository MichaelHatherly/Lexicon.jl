
### TODO: remove. Until Docile is tagged we need master here. ###
Pkg.checkout("Docile")

module LexiconTests

using Docile
@document

using Docile.Interface, Lexicon, FactCheck

import Lexicon: Query

include("testcases.jl")

@show @query(f())
@show Query((which(f, ()),), 0)

include("facts/query-parsing.jl")
include("facts/querying-results.jl")
include("facts/rendering.jl")

end
