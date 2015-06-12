["Display query results in the Julia REPL."]

Base.writemime(io::IO, mime::MIME"text/plain", results::Results) = writeobj(io, mime, results)

function writeobj(io::IO, mime::MIME"text/plain", results::Results)
    println(io)
    if isempty(results.data)
        print(io, "No results found.")
        return
    end
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

function truncated(io::IO, text, from::Int, maxwidth::Int)
    for (n, c) in enumerate(text)
        n < (maxwidth - from) || (print(io, "…"); break)
        write(io, c)
    end
end

sortresults!(results::Results) = sort!(
    results.data,
    by = result -> result.score,
    rev = true
    )

columncount(results::Results) = length(digits(length(results.data)))

# Show Objects. #

function showobj(io::IO, result::Result, columns::Int)
    mod, obj = result.mod, result.object
    highlight_exported(io, mod, obj)
    text = sprint(showobj, mod, obj)
    truncated(io, text, length(string(mod)) + columns, Base.tty_size()[2])
end

function showobj(io::IO, mod::Module, obj::Function)
    print(io, ".", name(mod, obj))
    meta = Cache.getmeta(mod, obj)
    if meta[:category] == :macro
        print(io, "(", join(meta[:signature].args[2:end], ", "), ")")
    end
end
showobj(io::IO, mod::Module, obj::Module) = print(io)
showobj(io::IO, mod::Module, obj::QualifiedSymbol) = print(io, ".", obj.sym)

if VERSION < v"0.4-dev"
    showobj(io::IO, mod::Module, obj::DataType) = print(io, ".", obj)
else
    function showobj(io::IO, mod::Module, obj::DataType)
        print(io, last(@compat(split(sprint(show, obj), string(mod), limit = 2))))
    end
end

# Don't show the line and file info.
showobj(io::IO, mod::Module, obj::Method) = print(io, ".", split(string(obj), " at ")[1])

showobj(io::IO, mod::Module, obj::Aside) = print(io, ".[ASIDE]")

function highlight_exported(io, mod, obj)
    exports = Cache.findmeta(mod, obj, :exports, Set{Symbol})
    isnull(exports) && throw(ErrorException("No exports found."))
    color = name(mod, obj) in get(exports) ? :green : :none
    print_with_color(color, io, string(mod))
end
