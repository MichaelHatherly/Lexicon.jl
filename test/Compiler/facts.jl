facts("Compiler.") do
    context("Basics.") do
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
        Lexicon.Compiler.compile!(out)
    end
end
