facts("Rendering.") do

    output = IOBuffer()

    context("Query output.") do

        writemime(output, MIME"text/plain"(), run(@query("")))
        writemime(output, MIME"text/plain"(), run(@query("",1)))
        writemime(output, MIME"text/plain"(), run(@query("",2)))
        writemime(output, MIME"text/plain"(), run(@query("",3)))
        writemime(output, MIME"text/plain"(), run(@query("",4)))
        writemime(output, MIME"text/plain"(), run(@query("",5)))

        writemime(output, MIME"text/plain"(), run(@query(@doc())))
        writemime(output, MIME"text/plain"(), run(@query(Docile.@doc())))

        writemime(output, MIME"text/plain"(), run(@query(Docile.meta())))

        writemime(output, MIME"text/plain"(), run(@query(Docile.meta)))

        writemime(output, MIME"text/plain"(), run(@query(Docile.Entry, 2)))

        writemime(output, MIME"text/plain"(), run(@query(Docile)))

    end

    context("Doctests output.") do

        writemime(output, MIME"text/plain"(), doctest(Docile))
        writemime(output, MIME"text/plain"(), doctest(Docile.Interface))
        writemime(output, MIME"text/plain"(), doctest(Lexicon))

        writemime(output, MIME"text/plain"(), passed(doctest(Docile)))
        writemime(output, MIME"text/plain"(), failed(doctest(Docile.Interface)))
        writemime(output, MIME"text/plain"(), skipped(doctest(Lexicon)))

    end

    context("Saving static content.") do
        for modname in (Lexicon, Docile, Docile.Interface), ft in ("md", "html")
            dir = joinpath(tempdir(), randstring())
            f = joinpath(dir, "$(modname).$(ft)")
            save(f, modname; mathjax = true)
            rm(dir, recursive = true)
        end
    end

end
