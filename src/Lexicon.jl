module Lexicon

"""
!!summary(Documentation generator and viewer for the Julia Language.)

It provides access to the documentation created by
[*Docile*][https://github.com/MichaelHatherly/Docile.jl].
"""
Lexicon

# Conditional importing of the `Markdown` module.
if VERSION < v"0.4-dev+1488"
    include("../deps/Markdown/src/Markdown.jl")
    import .Markdown
end


include("Utilities.jl")                             # Code useful across submodules.
include(joinpath("Doctest", "Doctest.jl"))
include(joinpath("Documents", "Documents.jl"))      # API for creating static documentation.
include(joinpath("Query", "Query.jl"))
include(joinpath("Render", "Render.jl"))            # API for creating static documentation.
include(joinpath("REPL", "REPL.jl"))
include(joinpath("Extensions", "Extensions.jl"))

end
