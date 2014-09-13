module Lexicon

import Markdown
import AnsiColor: colorize

import Docile.Interface: manual # extending

import Base: push!, length, writemime
import Base.Meta: isexpr

export @query, query, manual, save, doctest, passed, failed, skipped

using Docile, Docile.Interface
@docstrings {"../doc/manual.md"}

include("types.jl")
include("query.jl")
include("render.jl")
include("doctest.jl")

end # module
