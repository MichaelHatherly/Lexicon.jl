OS_NAME == :Windows && Pkg.add("FactCheck") # Hack for appveyor.

module LexiconTests

using Compat, FactCheck

import Lexicon

include(joinpath("Elements", "facts.jl"))
include(joinpath("Queries", "facts.jl"))

isinteractive() || FactCheck.exitstatus()

end
