module Lexicon

include("Utilities.jl")

include(joinpath("Generate", "Generate.jl"))
include(joinpath("Query", "Query.jl"))

"""

# Lexicon

Documentation extensions for Julia.

### Package Exports

$(join(["- $(n)" for n in names(Lexicon)], "\n"))

"""
Lexicon

end # module
