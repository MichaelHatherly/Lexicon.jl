
### TODO: remove. Until Docile is tagged we need master here. ###
Pkg.checkout("Docile")

module LexiconTests

reload("Lexicon")

using Docile
@document

using Docile.Interface, Lexicon, FactCheck

import Lexicon: Query

include("testcases.jl")

include("facts/query-parsing.jl")
include("facts/querying-results.jl")
include("facts/rendering.jl")

end
