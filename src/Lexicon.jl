module Lexicon

import Markdown

import Docile.Interface:

    parsedocs

import Base:

    start,
    next,
    done,
    length,
    push!,
    run,
    writemime,
    ==

using

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
    EachEntry,

    startgenidx,
    savegenidx

@document

include("query.jl")
include("render.jl")
include("doctest.jl")
include("filtering.jl")

__init__() = setup_help() # Hook into the REPL's `?`.

end # module
