facts("Rendering.") do

    output = IOBuffer()

    context("Query output.") do

        writemime(output, MIME"text/plain"(), run(@query("")))
        writemime(output, MIME"text/plain"(), run(@query("",1)))
        writemime(output, MIME"text/plain"(), run(@query("",2)))
        writemime(output, MIME"text/plain"(), run(@query("",3)))
        writemime(output, MIME"text/plain"(), run(@query("",4)))
        writemime(output, MIME"text/plain"(), run(@query("",5)))

        writemime(output, MIME"text/plain"(), run(@query(@document())))
        writemime(output, MIME"text/plain"(), run(@query(Docile.@document())))

        writemime(output, MIME"text/plain"(), run(@query(Docile.meta())))

        writemime(output, MIME"text/plain"(), run(@query(Docile.meta)))

        writemime(output, MIME"text/plain"(), run(@query(Docile.Interface.Entry, 2)))

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
        index  = Index()
        config = Config(include_internal = true)
        for modname in (Lexicon, Docile, Docile.Interface), ft in ("md", "html")
            dir = joinpath(tempdir(), randstring())
            f = joinpath(dir, "$(modname).$(ft)")
            # TODO: update / save index is not implemented for html
            if ft == "md"
                update!(index, save(f, modname, config; mathjax = true))
                save(joinpath(dir, "index_$(modname).$(ft)"), index, config)
            else
                save(f, modname, config; mathjax = true)
            end
            rm(dir, recursive = true)
        end
    end

    if VERSION < v"0.4.0-dev+4393"
        context("Testing relpath.") do
            sep = Base.path_separator
            filepaths = [
                "$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)",
                "$(sep)home$(sep)dir2_withendsep$(sep)",
                "$(sep)home$(sep)test.md",
                "$(sep)home",
                # Special cases
                "$(sep)",
                "$(sep)home$(sep)$(sep)$(sep)"
                ]

            startpaths = [
                "$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)genindex.md",
                "$(sep)multi_docs$(sep)genindex.md",
                "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)",
                "$(sep)home$(sep)dir2_withendsep$(sep)",
                "$(sep)home$(sep)test.md",
                "$(sep)home",
                # Special cases
                "$(sep)",
                "$(sep)home$(sep)$(sep)$(sep)"
                ]

            # generated with python's relpath
            relpath_expected_results = [
                "..$(sep)Lexicon.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "..$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)Lexicon.md",
                "..$(sep)lib$(sep)file1.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "home$(sep)user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "user$(sep).julia$(sep)v0.4$(sep)Lexicon$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)..$(sep)..$(sep)..$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "..$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "..$(sep)user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "home$(sep)user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "user$(sep).julia$(sep)v0.4$(sep)Docile$(sep)docs$(sep)api$(sep)Docile.md",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)dir_withendsep",
                "..$(sep)..$(sep)home$(sep)user$(sep)dir_withendsep", ".", "..$(sep)user$(sep)dir_withendsep",
                "..$(sep)user$(sep)dir_withendsep", "user$(sep)dir_withendsep",
                "home$(sep)user$(sep)dir_withendsep", "user$(sep)dir_withendsep",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)dir2_withendsep",
                "..$(sep)..$(sep)home$(sep)dir2_withendsep", "..$(sep)..$(sep)dir2_withendsep", ".",
                "..$(sep)dir2_withendsep", "dir2_withendsep", "home$(sep)dir2_withendsep", "dir2_withendsep",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)test.md",
                "..$(sep)..$(sep)home$(sep)test.md", "..$(sep)..$(sep)test.md", "..$(sep)test.md", ".",
                "test.md", "home$(sep)test.md", "test.md", "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..",
                "..$(sep)..$(sep)home", "..$(sep)..", "..", "..", ".", "home", ".",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..", "..$(sep)..",
                "..$(sep)..$(sep)..", "..$(sep)..", "..$(sep)..", "..", ".", "..",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..", "..$(sep)..$(sep)home",
                "..$(sep)..", "..", "..", ".", "home", "."
                ]

            idx = 0
            for filep in filepaths
                for startp in startpaths
                    res = Lexicon.relpath(filep, startp)
                    idx += 1
                    @fact res --> relpath_expected_results[idx] "Excpected: $(relpath_expected_results[idx])"
                end
            end

            # Additional cases
            @fact_throws ArgumentError Lexicon.relpath("$(sep)home$(sep)user$(sep)dir_withendsep$(sep)", "")
            @fact_throws ArgumentError Lexicon.relpath("", "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)")

        end
    end

end
