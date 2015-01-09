module Lexicon

import Markdown

import Docile.Interface:

    parsedocs

import Base:

    length,
    push!,
    run,
    writemime,
    ==

using

    AnsiColor,
    Base.Meta,
    Compat,
    Docile,
    Docile.Interface

export

    @query,
    query,
    save,

    doctest,
    failed,
    passed,
    skipped

@document

include("query.jl")
include("render.jl")
include("doctest.jl")

__init__() = setup_help() # Hook into the REPL's `?`.

end # module
