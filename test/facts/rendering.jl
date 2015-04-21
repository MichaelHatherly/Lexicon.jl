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

    if VERSION < v"0.4-"
        context("Testing relpath.") do
            sep = Base.path_separator
            filepaths = [
                "$(sep)home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "$(sep)home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "$(sep)home$(sep)user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)",
                "$(sep)home$(sep)dir2_withendsep$(sep)",
                "$(sep)home$(sep)test.md",
                "$(sep)home",
                # Special cases
                "$(sep)",
                "$(sep)home$(sep)$(sep)$(sep)"
            ]
            startpaths = [
                "$(sep)home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)genindex.md",
                "$(sep)multi_docs$(sep)genindex.md",
                "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)",
                "$(sep)home$(sep)dir2_withendsep$(sep)",
                "$(sep)home$(sep)test.md",
                "$(sep)home",
                # Special cases
                "$(sep)",
                "$(sep)home$(sep)$(sep)$(sep)"
            ]
            relpath_expected_results = [
                "..$(sep)Test1.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "..$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "..$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "..$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)Test1.md",
                "..$(sep)lib$(sep)file1.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "home$(sep)user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "user$(sep).julia$(sep)Test1$(sep)docs$(sep)api$(sep)lib$(sep)file1.md",
                "..$(sep)..$(sep)..$(sep)..$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "..$(sep)..$(sep)home$(sep)user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "..$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "..$(sep)user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "..$(sep)user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "home$(sep)user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "user$(sep).julia$(sep)测试2$(sep)docs$(sep)api$(sep)测试2.md",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)dir_withendsep",
                "..$(sep)..$(sep)home$(sep)user$(sep)dir_withendsep",".","..$(sep)user$(sep)dir_withendsep",
                "..$(sep)user$(sep)dir_withendsep","user$(sep)dir_withendsep",
                "home$(sep)user$(sep)dir_withendsep","user$(sep)dir_withendsep",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)dir2_withendsep",
                "..$(sep)..$(sep)home$(sep)dir2_withendsep","..$(sep)..$(sep)dir2_withendsep",".",
                "..$(sep)dir2_withendsep","dir2_withendsep","home$(sep)dir2_withendsep","dir2_withendsep",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)test.md","..$(sep)..$(sep)home$(sep)test.md",
                "..$(sep)..$(sep)test.md","..$(sep)test.md",".","test.md","home$(sep)test.md","test.md",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..","..$(sep)..$(sep)home","..$(sep)..",
                "..","..",".","home",".","..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..","..$(sep)..",
                "..$(sep)..$(sep)..","..$(sep)..","..$(sep)..","..",".","..",
                "..$(sep)..$(sep)..$(sep)..$(sep)..$(sep)..","..$(sep)..$(sep)home","..$(sep)..",
                "..","..",".","home","."
            ]
            idx = 0
            for filep in filepaths
                for startp in startpaths
                    res = Lexicon.relpath(filep, startp)
                    idx += 1
                    @fact res => relpath_expected_results[idx] "Excpected: $(relpath_expected_results[idx])"
                end
            end

            # Additional cases
            @fact_throws ArgumentError Lexicon.relpath("$(sep)home$(sep)user$(sep)dir_withendsep$(sep)", "")
            @fact_throws ArgumentError Lexicon.relpath("", "$(sep)home$(sep)user$(sep)dir_withendsep$(sep)")
        end
    end

end
