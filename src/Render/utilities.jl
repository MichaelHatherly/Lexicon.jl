["Rendering helpers unrelated to specific output formats."]

# Hook into Docile's docstring parsing mechanism.
parsedocs(::Format{MarkdownFormatter}, raw, mod, obj) = Markdown.parse(raw)

typealias Object Union(
    Module,
    Function,
    Method,
    DataType,
    QualifiedSymbol,
    Aside,
    )

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

# Symbolic names. #

name(mod, m::Method) = m.func.code.name

name(mod, m::Module) = module_name(m)

name(mod, t::DataType) = t.name.name

function name(mod, obj::Function)
    meta = Cache.getmeta(mod, obj)
    if meta[:category] == :macro
        meta[:signature].args[1]
    else
        symbol(string(obj))
    end
end

name(mod, q::QualifiedSymbol) = q.sym

name(mod, aside::Aside) = symbol("")

# Show Objects. #

function showobj(io::IO, result::Result, columns::Int)
    mod, obj = result.mod, result.object
    highlight_exported(io, mod, obj)
    text = sprint(showobj, mod, obj)
    truncated(io, text, length(string(mod)) + columns, Base.tty_size()[2])
end

function showobj(io::IO, mod::Module, obj::Function)
    print(io, ".")
    meta = Cache.getmeta(mod, obj)
    if meta[:category] == :macro
        print(io, "@", meta[:signature])
    else
        print(io, obj)
    end
end
showobj(io::IO, mod::Module, obj::Module) = print(io)
showobj(io::IO, mod::Module, obj::QualifiedSymbol) = print(io, ".", obj.sym)

function showobj(io::IO, mod::Module, obj::DataType)
    print(io, last(@compat(split(sprint(show, obj), string(mod), limit = 2))))
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
