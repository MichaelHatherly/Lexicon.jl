## Query parsing. -----------------------------------------------------------------------

immutable Head{S} end

macro H_str(text)
    heads = [Head{symbol(t)} for t in split(text, ", ")]
    Expr(:(::), Expr(:call, :Union, heads...))
end

typealias Queryable Union(Symbol, Expr, AbstractString)

type Query
    objects :: Tuple
    mods    :: Set{Module}
    index   :: Int

    Query(objects, modname, index) = new(objects, Set([modname]), index)
    Query(objects, index)          = new(objects, documented(), index)
end

# Needed for testing.
function (==)(a::Query, b::Query)
    res = length(a.objects) == length(b.objects)
    for (x, y) in zip(a.objects, b.objects)
        res &= x == y
    end
    res &= isempty(setdiff(a.mods, b.mods))
    res &= a.index == b.index
end

type Match
    entry::Entry
    objects::Set

    Match(entry) = new(entry, Set())
end

push!(match::Match, object) = push!(match.objects, object)

type QueryResults
    query   :: Query
    matches :: Dict{AbstractEntry, Match}
    scores  :: Dict{Float64, Set{AbstractEntry}}

    QueryResults(query) = new(
        query,
        Dict{AbstractEntry, Match}(),
        Dict{Float64, Set{AbstractEntry}}()
        )
end

length(res::QueryResults) = sum([length(m.objects) for m in values(res.matches)])

function push!(res::QueryResults, entry, object, score)
    score ≡ 0 && return
    if !haskey(res.matches, entry)
        res.matches[entry] = Match(entry)
        if haskey(res.scores, score)
            push!(res.scores[score], entry)
        else
            res.scores[score] = Set{AbstractEntry}([entry])
        end
    end
    push!(res.matches[entry], object)
end

push!(res::QueryResults, entry::Entry{:comment}, object, score) = res

## Construct a `Query` object.

macro query(args...) esc(query(args...)) end

query(ex::Queryable, index = 0) = build((objects(ex), modname(ex), index)...)

query(other...) = throw(ArgumentError("Invalid arguments: query($(other...))."))

build(objects, mod, index) = :(Lexicon.Query(tuple($(objects...)), $(mod), $(index)))
build(objects, ::Nothing, index) = :(Lexicon.Query(tuple($(objects...)), $(index)))

## Get a module name from an expression or `nothing`.

modname(ex::Expr) = modname(Head{ex.head}(), ex)

modname(other) = nothing

modname(H"call", ex) = modname(ex.args[1])
modname(H"macrocall", ex) = modname(ex.args[1])

modname(H".", ex) = ex.args[1]

## Get the objects contained in an expression.

objects(ex::Expr) = objects(Head{ex.head}(), ex)

objects(s::AbstractString) = [s]
objects(s::Symbol)         = [s, quot(s)]
objects(H"quote", ex)      = [ex.args[1], ex]

objects(H".", ex) = [ex, ex.args[2]]

objects(H"call", ex) = [:(which($(ex.args[1]), Lexicon.typesof($(ex.args[2:end])...)))]

objects(H"macrocall", ex) =
    isexpr(ex.args[1], :(.)) ?
    [:(getfield($(modname(ex)), $(ex.args[1].args[2])))] :
    [ex.args[1]]

# Hack around some weirdness in Base, TODO: report!
function typesof(args...)
    out = Any[]
    for arg in args
        if isa(arg, Type)
            push!(out, Type{arg})
        else
            push!(out, typeof(arg))
        end
    end
    tuple(out...)
end

macro help(args...)
    ex = (isinteractive() && length(args) ≡ 1) ? :(Base.Help.@help $(args[1])) : :()
    :($(esc(ex)); println(); run($(esc(query(args...)))))
end

## Running queries. ---------------------------------------------------------------------

function partial_signature_matching(f::Function, sig::Tuple)
    meths = Set{Method}()
    for method in f.env
        msig = method.sig
        for n = 1:length(msig)
            isequal(typeintersect(msig[1:n], sig), None) || push!(meths, method)
        end
    end
    meths
end

function query(f::Function, sig::Tuple, index = 0)
    methods = tuple(partial_signature_matching(f, sig)...)
    run(Query(methods, index))
end

# For each object in a query search every specified module for it's documentation.
function run(query::Query)
    res = QueryResults(query)
    for modname in query.mods, object in query.objects
        isdocumented(modname) && append_result!(res, object, metadata(modname))
    end
    res
end

# Full text search.
function append_result!(res, query::AbstractString, meta)
    for (object, entry) in entries(meta)
        score = calculate_score(query, data(docs(entry)), writeobj(object, entry))
        push!(res, entry, object, score)
    end
end

# Basic text importance scoring.
calculate_score(query, text, object) = length(split(string(object, text), query)) - 1

# Generic function.
function append_result!(res, func::Function, meta)
    ms = isgeneric(func) ? Set(methods(func)) : Set{Method}() # Handle macros.
    for (object, entry) in entries(meta)
        if object ≡ func
            push!(res, entry, object, 2)
        elseif object ∈ ms
            push!(res, entry, object, 1)
        end
    end
end

function append_result!(res, dt::DataType, meta)
    ms = Set(wrap_non_iterables(methods(mostgeneral(dt))))
    for (object, entry) in entries(meta)
        if object ≡ dt
            push!(res, entry, object, 2)
        elseif object ∈ ms
            push!(res, entry, object, 1)
        end
    end
end

append_result!(res, other, meta) = nothing

mostgeneral(T::DataType) = T{[tvar.ub for tvar in T.parameters]...}

wrap_non_iterables(obj) = applicable(start, obj) ? obj : tuple(obj)

typealias SimpleObject Union(Symbol, Method, Module)

function append_result!(res, object::SimpleObject, meta)
    if haskey(entries(meta), object)
        push!(res, entries(meta)[object], object, 1)
    end
end

function setup_help()
    # Some environments, such as IJulia & Juno don't have an active repl.
    if isdefined(Base, :active_repl)
        repl = Base.active_repl

        julia_mode = repl.interface.modes[1]
        help_mode  = repl.interface.modes[3]

        help_mode.on_done = Base.REPL.respond(repl, julia_mode) do line
            parse("Lexicon.@help $(line)", raise = false)
        end
    end
end
