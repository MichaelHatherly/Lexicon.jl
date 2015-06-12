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

# Returns for the  module ``m`` all documented objects after applying any 
# configuration filter for the node ``n``.
function objectsfiltered(n::Node{Docs}, m::Module)
    objects = Cache.objects(m)
    f = findconfig(n, :filter, Function)
    objects = isnull(f) ? objects : filter(get(f), objects)
end

"""
Is the documented object ``obj`` exported from the given module ``m``?
"""
isexported(m::Module, obj) = name(m, obj) in Cache.getmeta(Cache.getmodule(m))[:exports]

"""
Is the object ``obj`` from module ``m`` a Docile category ``cat`` or one of the categories ``cats``.
"""
:iscategory

iscategory(m::Module, obj, cat::Symbol)          = Cache.getmeta(m, obj)[:category] == cat
iscategory(m::Module, obj, cats::Vector{Symbol}) = Cache.getmeta(m, obj)[:category] in cats

"""
Is the docstring's location of object ``obj`` from module ``m``` in one of the files ``files``.
"""
function isinfile(m::Module, obj, files::Vector)
    textsource = Cache.getmeta(m, obj)[:textsource][2]
    for f in files
        endswith(textsource, f) && return true
    end
    false
end


hasparameters(expr::Expr) = length(expr.args) > 1 && isexpr(expr.args[2], :parameters)

"""
Extract the expressions from a ``{}`` in a function definition.
"""
gettvars(expr::Expr) = isexpr(expr.args[1], :curly) ? expr.args[1].args[2:end] : Any[]

"""
Extract the expressions representing a method definition's arguments withouth keyword arguments.
"""
getargs(expr::Expr) = hasparameters(expr) ? expr.args[3:end] : expr.args[2:end]

"""
Extract the expressions representing a method definition's keyword arguments.
"""
getkwargs(expr::Expr) = hasparameters(expr) ? expr.args[2].args[2:end] : Any[]

# Helper
hasparameters(expr::Expr) = length(expr.args) > 1 && isexpr(expr.args[2], :parameters)
