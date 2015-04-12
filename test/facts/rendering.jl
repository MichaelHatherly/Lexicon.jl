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

    context("Testin relpath.") do
        filepaths = ["/home/user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
                        "/home/user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
                        "/home/user/.julia/v0.4/Docile/docs/api/Docile.md",
                        "/home/user/dir_withendsep/",
                        "/home/dir2_withendsep/",
                        "/home/test.md",
                        "/home",
                        # Special cases
                        "/",
                        "/home///"
                    ]
        startpaths = ["/home/user/.julia/v0.4/Lexicon/docs/api/genindex.md",
                        "/multi_docs/genindex.md",
                        "/home/user/dir_withendsep/",
                        "/home/dir2_withendsep/",
                        "/home/test.md",
                        "/home",
                        # Special cases
                        "/",
                        "/home///"
                    ]

        # generated with python's relpath
        relpath_expected_results = ["../Lexicon.md",
            "../../home/user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "../.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "../user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "../user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
             "user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "home/user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "user/.julia/v0.4/Lexicon/docs/api/Lexicon.md",
            "../lib/file1.md", "../../home/user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "../.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "../user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "../user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "home/user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
             "user/.julia/v0.4/Lexicon/docs/api/lib/file1.md",
            "../../../../Docile/docs/api/Docile.md",
            "../../home/user/.julia/v0.4/Docile/docs/api/Docile.md",
            "../.julia/v0.4/Docile/docs/api/Docile.md",
            "../user/.julia/v0.4/Docile/docs/api/Docile.md",
            "../user/.julia/v0.4/Docile/docs/api/Docile.md",
            "user/.julia/v0.4/Docile/docs/api/Docile.md",
            "home/user/.julia/v0.4/Docile/docs/api/Docile.md",
            "user/.julia/v0.4/Docile/docs/api/Docile.md",
            "../../../../../../dir_withendsep", "../../home/user/dir_withendsep", ".",
            "../user/dir_withendsep", "../user/dir_withendsep", "user/dir_withendsep",
            "home/user/dir_withendsep", "user/dir_withendsep",
            "../../../../../../../dir2_withendsep", "../../home/dir2_withendsep",
            "../../dir2_withendsep", ".", "../dir2_withendsep", "dir2_withendsep",
            "home/dir2_withendsep", "dir2_withendsep", "../../../../../../../test.md",
            "../../home/test.md", "../../test.md", "../test.md", ".", "test.md", "home/test.md",
            "test.md", "../../../../../../..", "../../home", "../..", "..", "..", ".", "home",
            ".", "../../../../../../../..", "../..", "../../..", "../..", "../..", "..", ".",
            "..", "../../../../../../..", "../../home", "../..", "..", "..", ".", "home", "."
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
        @fact_throws ArgumentError Lexicon.relpath("/home/user/dir_withendsep/", "")
        @fact_throws ArgumentError Lexicon.relpath("", "/home/user/dir_withendsep/")

    end

end
