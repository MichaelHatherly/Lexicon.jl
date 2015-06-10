module REPLMode

"""
A REPL mode for interacting with Lexicon's query system.
"""
REPLMode

using Compat

import ..Queries
import Base.Meta: isexpr

runquery(line) = :(Lexicon.Queries.runquery(Lexicon.Queries.@query_str($(strip(line)))))

include("version-0.$(VERSION < v"0.4-dev" ? "3" : "4").jl")

function __init__()
    isdefined(Base, :active_repl) && setup_help_mode(Base.active_repl)
    nothing
end

function setup_help_mode(repl::Base.REPL.LineEditREPL)
    julia_mode = repl.interface.modes[1]
    help_mode  = repl.interface.modes[3]
    help_mode.on_done = Base.REPL.respond(help, repl, julia_mode)
end
setup_help_mode(other) = nothing

end
