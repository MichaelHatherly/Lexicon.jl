import Lexicon.Elements:

    document,
    section,
    page,
    docs

import Lexicon.Render: checkconfig!


facts("Terminal.") do
    context("Basics.") do
        buf = IOBuffer()
        results = Lexicon.Queries.runquery(Lexicon.Queries.@query_str("\"\""))
        writemime(buf, "text/plain", results)
    end
end

facts("Render.") do

    context("Check config.") do

        out = document(section(page("", title = :Page)))
        checkconfig!(out.children[1].children[1])

        @fact haskey(out.children[1].children[1].cache, :outname)          => true
        @fact out.children[1].children[1].data[:title]                     => "Page"
        @fact out.children[1].children[1].cache[:outname]                  => "page"
        @fact isa(out.children[1].children[1].data[:title], UTF8String)    => true
        @fact isa(out.children[1].children[1].cache[:outname], UTF8String) => true

        @fact_throws ArgumentError checkconfig!(out.children[1])

        out = document(section(section(page(docs("", title = "docs"), title = :Page),
                        title = "Inner Section",  outname = "chinese 出名字"),
                        title = :Outer_Section), title = "Documentation")
        checkconfig!(out)

        @fact haskey(out.children[1].children[1].children[1].children[1].cache, :outname) => false

        @fact out.children[1].children[1].children[1].cache[:outname] => "page"
        @fact out.children[1].children[1].cache[:outname]             => "chinese 出名字"
        @fact out.children[1].cache[:outname]                         => "outer_section"
        @fact out.cache[:outname]                                     => "documentation"

    end

end
