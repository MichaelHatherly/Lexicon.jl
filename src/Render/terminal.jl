["Display query results in the Julia REPL."]

Base.writemime(io::IO, mime::MIME"text/plain", results::Results) = writeobj(io, mime, results)

function writeobj(io::IO, mime::MIME"text/plain", results::Results)
    if isempty(results.data)
        print(io, "No results found.")
        return
    end
    println(io)
    sortresults!(results)
    if 1 <= results.query.index <= length(results.data)
        writeobj(io, mime, results.data[results.query.index])
    elseif length(results.data) == 1
        writeobj(io, mime, results.data[1])
    else
        columns = columncount(results) + 1
        for (n, result) in enumerate(results.data)
            print_with_color(:white, io, lpad(n, columns), ": ")
            showobj(io, result, columns + 2)
            n < length(results.data) && println(io)
        end
    end
end

function writeobj(io::IO, mime::MIME"text/plain", result::Result)
    print(io, " "); showobj(io, result, 1) # Some indentation.
    println(io, "\n")
    Markdown.term(io, Cache.getparsed(result.mod, result.object))
end
