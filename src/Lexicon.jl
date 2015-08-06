module Lexicon

include("Utilities.jl")

include(joinpath("Generate", "Generate.jl"))

import .Generate: @file

include(joinpath("Query", "Query.jl"))

# Package exports.

export @file

"""

# Lexicon

Documentation extensions for Julia.

### Package Exports

$(join(["- ``$(n)``" for n in names(Lexicon)], "\n"))

"""
Lexicon

end # module
