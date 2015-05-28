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
include(joinpath("Render", "Render.jl"))
include(joinpath("Query", "Query.jl"))
include(joinpath("REPL", "REPL.jl"))
include(joinpath("Externals", "Externals.jl"))

end # module

