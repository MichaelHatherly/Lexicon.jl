module Render

"""

"""
Render

using Compat

import Docile: Cache, Collector, Formats
import Docile.Formats: Format, MarkdownFormatter, parsedocs
import Docile.Collector: Aside, QualifiedSymbol
import Base.Meta: isexpr

import ..Utilities: url
import ..Elements: Node, Document, Section, Page, Docs, rename, findconfig
import ..Queries: Results, Result
import ..Externals: writemkdocs

import ..Markdown

include("utilities.jl")
include("terminal.jl")
include("markdown.jl")

end
