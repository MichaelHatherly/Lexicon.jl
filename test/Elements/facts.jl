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
    findconfig

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

    context("Parent reference.") do

        out = document(section(page(docs(""), title = "p"), title = "s"), title = "d")

        @fact (out.children[1].parent == out) => true
        @fact (out.children[1].children[1].parent == out.children[1]) => true
        @fact (out.children[1].children[1].children[1].parent == out.children[1].children[1]) => true

    end

    context("General.") do

        @fact config(; a = 20) => @compat(Dict{Symbol, Any}(:a => 20))

        @fact (config(; a = 20) == config(; a = 20)) => true
        @fact (config(; a = 20) == config(; a = 50)) => false

        @fact (document(a = 20, b = 30) == document(a = 2, b = 3)) => false
        @fact (document(section(), section(a = 20)) == document(section(), section())) => false

        @fact (document(section(page(docs(""), title = "p"), title = "s"), title = "d") ==
            document(section(page(docs(""), title = "p"), title = "s"), title = "d")) => true

    end

    context("Find config.") do

        out = document(section(section(page(docs("", doc = 1, title = "docs",), p = 2,
                        title = "page",), title = "Nested Section", ns = 3,),   s = 4,
                        title = "Section",), title = "Docile Documentation",    d = 5,)

        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :title, AbstractString)) => "docs"
        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :doc, Int)) => 1
        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :p, Int))   => 2
        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :ns, Int))  => 3
        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :s, Int))   => 4
        @fact get(findconfig(out.children[1].children[1].children[1].children[1], :d, Int))   => 5

        value = findconfig(out.children[1].children[1].children[1].children[1], :someother, Any)
        @fact isnull(value) => true
        @fact_throws NullException get(value)

        @fact get(findconfig(out.children[1].children[1], :d, Int)) => 5

    end

end
