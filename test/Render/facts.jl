facts("Terminal.") do
    context("Basics.") do
        buf = IOBuffer()
        results = Lexicon.Queries.runquery(Lexicon.Queries.@query_str("\"\""))
        writemime(buf, "text/plain", results)
    end
end
