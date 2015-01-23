module Lexicon

import Markdown

import Docile.Interface:

    parsedocs

import Base:

    start, stop, next,
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
    skipped,
    EachEntry


@document

include("query.jl")
include("render.jl")
include("doctest.jl")
include("filtering.jl")

__init__() = setup_help() # Hook into the REPL's `?`.

end # module
