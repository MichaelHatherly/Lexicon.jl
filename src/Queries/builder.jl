"""
Parse a given string ``text`` into a ``Query`` tree.

The tree can then be run to fetch matching documentation from Docile.
"""
macro query_str(text) buildquery(text) end

function buildquery(text::AbstractString)
    query, index = splitquery(text)
    index < 0 && throw(QueryBuildError("Index must be non-negative."))
    buildquery(parse(query), index)
end

## Simple base cases. ##

buildquery(text::AbstractString, index::Int) = :(Query(Text($(esc(text))), $(index)))

buildquery(sym::Symbol, index::Int) = :(Query(Object($(quot(sym)), $(esc(sym))), $(index)))

## Expression handling. ##

buildquery(ex::Expr, index::Int) = :(Query($(build(ex)), $(index)))

buildquery(other...) = throw(QueryBuildError("Invalid query syntax. '$(other)'"))

## Inner build methods. ##

build(text::AbstractString) = :(Text($(esc(text))))
build(sym::Symbol)          = :(Object($(quot(sym)), $(esc(sym))))
build(ex::Expr)             = build(Head{ex.head}(), ex)

function build(H"call", ex::Expr)
    func, args = ex.args[1], ex.args[2:end]
    # Logical Terms.
    func == :& && return :(And($(build(args[1])), $(build(args[2]))))
    func == :| && return :( Or($(build(args[1])), $(build(args[2]))))
    func == :! && return :(Not($(build(args[1]))))
    # Standard method calls.
    :(And($(build(func)), $(build(Expr(:tuple, args...)))))
end

build(H".", ex::Expr)     = :(Object($(ex.args[end]), $(esc(ex))))
build(H"tuple", ex::Expr) = :(ArgumentTypes($(esc(ex))))

build(H"macrocall", ex::Expr) = build(ex.args[1])

function build(H"::", ex::Expr)
    out = :(ReturnTypes($(esc(last(ex.args)))))
    length(ex.args) > 1 ? :(And($(build(ex.args[1])), $(out))) : out
end

function build(H"vect, vcat", ex::Expr)
    out = Expr(:ref, :Any)
    for arg in ex.args
        push!(out.args, buildvect(arg))
    end
    :(Metadata($(out)))
end

build(other...) = throw(QueryBuildError("Invalid query syntax. '$(other)'"))

buildvect(ex::Expr)  = Expr(:tuple, extractpair(ex)...)
buildvect(s::Symbol) = Expr(:tuple, quot(s), :(MatchAnything()))

buildvect(other...) = throw(QueryBuildError("Invalid metadata: '$(other)'"))

function extractpair(ex::Expr)
    isexpr(ex, :(=), 2) || throw(QueryBuildError("Write metadata as '[k = v, …]'. '$(ex)'"))
    k, v = ex.args; issymb(k)
    quot(k), esc(v)
end

issymb(s::Symbol) = true
issymb(x) = throw(QueryBuildError("Invalid key: '$(x)'. Use identifiers as keys. No quoting."))
