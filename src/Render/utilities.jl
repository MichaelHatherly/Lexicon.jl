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
        symbol(string("@", meta[:signature].args[1]))
    else
        obj.env.name
    end
end

name(mod, q::QualifiedSymbol) = q.sym

function name(mod, obj::Aside)
    linenumber, path = Cache.getmeta(mod, obj)[:textsource]
    return symbol("aside_$(first(splitext(basename(path))))_L$(linenumber)")
end

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

# Sets an ``:outname`` from the node's configuration or generates one from ``:title``
function setoutname!(n::Node)
    haskey(n.cache, :outname) && return
    haskey(n.data, :outname) && return n.cache[:outname] = utf8(string(n.data[:outname]))
    replace_chars = Set(Char[' ', '&', '-'])
    io = IOBuffer()
    for c in n.data[:title]
        c in replace_chars ? write(io, "_") : write(io, lowercase(string(c)))
    end
    n.cache[:outname] = utf8(takebuf_string(io))
end

function getheadertype(s::AbstractString)
    for i in 1:min(length(s), 7)
        s[i] != '#' && return i < 2 ? :none : symbol("header$(i-1)")
    end
    return :none
end

# Checks the node's configuration settings.
function checkconfig!{T}(n::Node{T})
    haskey(n.data, :title) || throw(ArgumentError("'$(rename(T))' has no key ':title'."))
    isa(n.data[:title], UTF8String) || (n.data[:title] = utf8(string(n.data[:title])))
    setoutname!(n)
    for child in n.children
        checkinner!(child)
    end
end
checkinner!(n) = return
checkinner!(n::Node{Section}) = checkconfig!(n)
checkinner!(n::Node{Page})    = checkconfig!(n)
