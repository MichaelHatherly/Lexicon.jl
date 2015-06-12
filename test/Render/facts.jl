facts("Terminal.") do
    context("Basics.") do
        buf = IOBuffer()
        results = Lexicon.Queries.runquery(Lexicon.Queries.@query_str("\"\""))
        writemime(buf, "text/plain", results)
    end

    context("Compile.") do
        out = document(
            :one,
            section(
                :two,
                page(
                    :three,
                    "",
                    docs(
                        :four,
                        "",
                        Lexicon,
                        Docile,
                        "",
                        Docile.Collector,
                        ),
                    "",
                    ),
                page(
                    :five,
                    "",
                    docs(
                        :six,
                        Docile.Cache,
                        "",
                        Docile.Formats,
                        Lexicon.Queries,
                        )
                    ),
                ),
            section(
                page(

                    ),
                ),
            section(
                page(
                    ),
                ),
            )
        Lexicon.Render.compile!(out)
    end
end
