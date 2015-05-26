module Render

"""
!!summary(Rendering and saving of documentation.)
"""
Render

export @RC_str, save, markdown, wrapstyle

import Docile: Formats

import ..Documents: Document, Section, Preformat, Pages, Page, ContentNode, STYLE_TAGS, getnodename


include("md.jl")    # Markdown rendering.

end
