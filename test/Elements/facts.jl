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
    Docs

facts("Elements.") do

    context("Tuple construction.") do

        @fact section() => (Section, (), Dict{Symbol, Any}())
        @fact page()    => (Page, (), Dict{Symbol, Any}())
        @fact docs()    => (Docs, (), Dict{Symbol, Any}())

        @fact section(section()) => (
            Section,
            ((Section, (), Dict{Symbol, Any}()),),
            Dict{Symbol, Any}())

        @fact section(page(), page()) => (
            Section,
            ((Page, (), Dict{Symbol, Any}()),
             (Page, (), Dict{Symbol, Any}()),),
            Dict{Symbol, Any}())

        @fact section(section(page(docs()))) => (
            Section,
            ((Section,
              ((Page,
                ((Docs,
                  (),
                  Dict{Symbol, Any}()),),
                Dict{Symbol, Any}()),),
              Dict{Symbol, Any}()),),
            Dict{Symbol, Any}())

        @fact page("", docs(), docs()) => (
            Page,
            ("",
             (Docs, (), Dict{Symbol, Any}()),
             (Docs, (), Dict{Symbol, Any}()),),
            Dict{Symbol, Any}())

    end

    context("Node construction.") do

        @fact document() => Node{Document}()

        @fact document(section()) => Node{Document}(
            Any[Node{Section}()],
            Dict{Symbol, Any}())

        @fact document(a = 1) => Node{Document}(
            Any[],
            @compat(Dict{Symbol, Any}(:a => 1)))

        @fact document(section(page(""))) => Node{Document}(
            Any[Node{Section}(
                    Any[Node{Page}(Any[""], Dict{Symbol, Any}())],
                    Dict{Symbol, Any}())],
            Dict{Symbol, Any}())

        @fact document(section(page(docs("")))) => Node{Document}(
            Any[Node{Section}(
                    Any[Node{Page}(
                            Any[Node{Docs}(
                                    Any[""],
                                    Dict{Symbol, Any}())],
                            Dict{Symbol, Any}())],
                    Dict{Symbol, Any}())],
            Dict{Symbol, Any}())

        @fact_throws ArgumentError document(page())
        @fact_throws ArgumentError document(page(section()))
        @fact_throws ArgumentError document(docs())
        @fact_throws ArgumentError document(section(section(section(""))))
        @fact_throws ArgumentError document(page(current_module()))
        @fact_throws ArgumentError document(section(current_module()))

    end

    context("Display.") do

        str_1 = """
        document(
            section(
                page(
                    docs(
                        Lexicon,
                    ),
                    title = "",
                ),
                page(
                    "a",
                ),
            ),
            section(
                page(
                    "a",
                ),
            ),
            section(
                page(
                    "a",
                ),
            ),
            b = :a,
        )
        """

        buf = IOBuffer()
        writemime(buf, "text/plain", eval(parse(str_1)))
        str_2 = takebuf_string(buf)

        @fact strip(str_1) => strip(str_2)

    end

end
