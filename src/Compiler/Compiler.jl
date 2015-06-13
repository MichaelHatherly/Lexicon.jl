module Compiler

"""
Stage two of generating static documentation.

Traverse the documentation tree and sort docstrings based on their position and
any given ``filter`` and ``sorter`` functions.

This stage is output format agnostic. Things such as mkdocs are done later.
"""
Compiler

using Compat

import Docile:

    Cache,
    Collector,
    Formats

import Docile.Formats:

    Format,
    MarkdownFormatter,
    parsedocs

import ..Elements:

    Elements,
    Node,
    Document,
    Section,
    Page,
    Docs

import ..Functors:

    Functor,
    GroupBy,
    FilterBy,
    SortBy,
    applyf


import ..Markdown


include("utilities.jl")
include("compile.jl")

end
