"""
Parse a given string ``text`` into a ``Query`` tree.

The tree can then be run to fetch matching documentation from Docile.

The syntax below don't show the ``query"..."`` and only show the ``...`` part:

    # Text matching "a" and "b" but not "c":
    "a" & "b" & !"c"

    # Text matching "a" with metadata pair ``:b => c``:
    "a" & [b = c]

    # Object ``f`` from module ``A.B``:
    A.B.f

    # Methods ``f`` from module ``A.B`` with signature ``(Int, Any)``:
    A.B.f(Int, Any)

    # The same as the previous example, but with return type ``(Bool,)``:
    A.B.f(Int, Any)::Bool

    # Macro ``@m`` in module ``M``. Note the ``()`` needed:
    M.@m()

    # All functions ``f`` with return type ``(Int, Bool)``:
    f::(Int, Bool)

    # Macro ``@n`` with matching text "macro":
    @n() & "macro"

    # Functions in module ``M`` matching signature ``(Int,) -> Bool``
    M & (Int,)::Bool

    # Metadata fields ``:a`` with any value and ``:b`` with value ``1``:
    [a, b = 1]

"""
macro query_str(text) buildquery(text) end

function buildquery(text::AbstractString)
    query, index = splitquery(text)
    index < 0 && throw(QueryBuildError("Index must be non-negative."))
    buildquery(parse(query), index)
end

# Simple base cases.

buildquery(s::AbstractString, index::Int) =
    :(Query(Text($(esc(s))), Any[], $(index)))

buildquery(s::Symbol, index::Int) =
    :(Query(Object($(quot(s)), $(esc(s))), Any[$(esc(s))], $(index)))

# Expression handling.

function buildquery(expr::Expr, index)
    mods = Expr(:ref, :Any)
    term = build!(expr, mods)
    :(Query($(term), $(mods), $(index)))
end

build!(s::AbstractString, mods::Expr) = :(Text($(esc(s))))

function build!(s::Symbol, mods::Expr)
    push!(mods.args, esc(s))
    :(Object($(quot(s)), $(esc(s))))
end

build!(expr::Expr, mods::Expr) = build!(Head{expr.head}(), expr, mods)

function build!(H"call", expr, mods)
    func, args = expr.args[1], expr.args[2:end]
    # Logical Terms.
    func == :& && return :(And($(build!(args[1], mods)), $(build!(args[2], mods))))
    func == :| && return :( Or($(build!(args[1], mods)), $(build!(args[2], mods))))
    func == :! && return :(Not($(build!(args[1], mods))))
    # Standard method calls.
    :(And($(build!(func, mods)), $(build!(Expr(:tuple, args...), mods))))
end

function build!(H".", expr, mods)
    mod, sym = expr.args
    push!(mods.args, esc(mod))
    :(Object($(sym), $(esc(expr))))
end

function build!(H"::", expr, mods)
    args = expr.args
    out  = buildreturn(last(args))
    length(args) == 1 ? out : :(And($(build!(first(args), mods)), $(out)))
end
buildreturn(ex::Expr)  = :(ReturnTypes($(esc(Expr(:tuple, ex.args...)))))
buildreturn(s::Symbol) = :(ReturnTypes($(esc(Expr(:tuple, s)))))

build!(H"tuple", expr, mods) = :(ArgumentTypes($(esc(expr))))

build!(H"macrocall", expr, mods) = build!(first(expr.args), mods)

# Handle 0.3 conversion for tuples in arrays. Just make it's type 'Any'.
makeref!(expr) = (unshift!(expr.args, :Any); expr.head = :ref)

function build!(H"vect, vcat", expr, mods)
    expr.args = [buildvect(arg) for arg in expr.args]
    makeref!(expr)
    :(Metadata($(expr)))
end
function buildvect(arg::Expr)
    err = QueryBuildError("Declare metadata with '[k = v, ...]' syntax.")

    isexpr(arg, :(=))     || throw(err)
    length(arg.args) == 2 || throw(err)

    k, v = arg.args

    isa(k, Symbol) || throw(QueryBuildError("Metadata keys must be identifiers"))

    Expr(:tuple, quot(k), esc(v))
end
buildvect(arg::Symbol) = Expr(:tuple, quot(arg), :(MatchAnything()))

buildvect(other...) = throw(QueryBuildError("Invalid metadata syntax: '$(other)'."))

build!(other...) = throw(QueryBuildError("Invalid query syntax."))

buildquery(other...) = throw(QueryBuildError("Invalid query syntax."))
