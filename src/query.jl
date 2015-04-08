## Query parsing. -----------------------------------------------------------------------

immutable Head{S} end

macro H_str(text)
    heads = [Head{symbol(t)} for t in split(text, ", ")]
    Expr(:(::), Expr(:call, :Union, heads...))
end

"Types that can be queried."
typealias Queryable Union(Symbol, Expr, AbstractString)

"""
Holds the parsed user query.

**Fields:**

* `objects`: The objects that will be searched for in metadata.
* `mods`:    Modules to be searched through for documentation.
* `index`:   1-based, for picking an individual entry to display out of a list.

"""
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

"An entry and the set of all objects that are linked to it."
type Match
    entry::Entry
    objects::Set

    Match(entry) = new(entry, Set())
end

push!(match::Match, object) = push!(match.objects, object)

"Stores the matching entries resulting from running a query."
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

"""
Create a `Query` object from the provided `args`.
The resulting query can then be `run` to retrieve matching results from currently loaded
documentation.

This is a low-level interface. For everyday usage in the REPL rather use the
built-in `?` mode, which Lexicon hooks into automatically.

The first argument must be the expression to search for. Supported expressions
include method calls, macros, constants, types, functions, and strings. An
optional integer argument may be used to only show documentation from one of
several results.

**Example:**

```julia
q = @query Lexicon.@query
run(q)
```

```julia
q = @query Lexicon.save 2
run(q)
```

**Note:** When searching documentation for an operator (`+`, `-`, etc.) it should
be enclosed in parentheses:

```julia
q = @query (+) 4
run(q)
```
"""
macro query(args...) esc(query(args...)) end

query(ex::Queryable, index = 0) = build((objects(ex), modname(ex), index)...)

query(other...) = throw(ArgumentError("Invalid arguments: query($(join(other, ", ")))."))

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

# Hack around some weirdness in Base.
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

"""
Search for all methods of a generic function `f` that match the signature `sig`.
Optionally, provide an index (1-based) to view an
individual entry if several different ones are found.
"""
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

"Basic text importance scoring."
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

const INDEXED = r"\s(\d+)$"

if VERSION < v"0.4-"
    function help(line)
        ex  = ismatch(INDEXED, line) ? nothing : parse("Base.Help.@help $(line)", raise = false)
        lex = parse("Lexicon.@query $(line)", raise = false)

        quote
            $(ex)
            println()
            run($(lex))
        end
    end
else
    function help(line)
        sline = symbol(line)
        iskey = isdefined(Base.Docs, :keywords) && haskey(Base.Docs.keywords, sline)

        ex, lex =
            # keywords can't be searched for in Lexicon.
            if iskey
                (:(Base.Docs.@repl $(sline)), nothing)
            else
                lex = :(run($(parse("Lexicon.@query $(line)", raise = false))))
                # Base REPL doesn't support indexing query results.
                if ismatch(INDEXED, line)
                    (nothing, lex)
                else
                    (parse("Base.Docs.@repl $(line)", raise = false), lex)
                end
            end

        # Check for string argument, not supported by base REPL. Call apropos.
        if isexpr(ex, :macrocall)
            ex =
                if length(ex.args) ≡ 2 && isa(ex.args[2], AbstractString)
                    :(Base.apropos($(ex.args[2])); println())
                else
                    result = gensym()
                    quote
                        $(result) = $(ex)
                        $(result) ≡ nothing || display($(result))
                    end
                end
        end

        quote
            try $(ex) catch end
            $(lex)
        end
    end
end

function setup_help()
    # Some environments, such as IJulia & Juno don't have an active repl.
    if isdefined(Base, :active_repl) && isa(Base.active_repl, Base.REPL.LineEditREPL)
        repl = Base.active_repl

        julia_mode = repl.interface.modes[1]
        help_mode  = repl.interface.modes[3]

        help_mode.on_done = Base.REPL.respond(repl, julia_mode) do line
            Lexicon.help(line)
        end
    end
end
