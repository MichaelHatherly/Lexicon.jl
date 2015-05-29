import Lexicon.Elements:

    document,
    section,
    page,
    docs,
    config,
    Node,
    Document,
    Section,
    Page,
    Docs,
    EmptyNodeError,
    ChildTypeError,
    ParentTypeError,
    MissingKeyError


facts("Elements.") do

    context("Empty Nodes.") do

        @fact_throws EmptyNodeError document(section(page(outname = "p",), outname = "s"), outname = "d")
        @fact_throws EmptyNodeError document(section(outname = "s"), outname = "d")
        @fact_throws EmptyNodeError document(outname = "d")

    end

end
