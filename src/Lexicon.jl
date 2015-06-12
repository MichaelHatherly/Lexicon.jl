module Lexicon

"""

"""
Lexicon

using Compat

# Conditional importing of the `Markdown` module.
if VERSION < v"0.4-dev+1488"
    include("../deps/Markdown/src/Markdown.jl")
    import .Markdown
end

include("Utilities.jl")

include(joinpath("Elements", "Elements.jl"))
include(joinpath("Queries", "Queries.jl"))
include(joinpath("REPLMode", "REPLMode.jl"))
include(joinpath("Externals", "Externals.jl"))
include(joinpath("Render", "Render.jl"))

end # module
