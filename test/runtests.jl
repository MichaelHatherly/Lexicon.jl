OS_NAME == :Windows && Pkg.add("FactCheck") # Hack for appveyor.

module LexiconTests

using Docile
@document

using Docile.Interface, Lexicon, FactCheck

import Lexicon: Query

include("testcases.jl")

include("facts/query-parsing.jl")
include("facts/querying-results.jl")
include("facts/rendering.jl")
include("facts/filtering.jl")

end
