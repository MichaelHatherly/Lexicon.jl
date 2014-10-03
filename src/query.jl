type MatchingEntries
    entries::Dict{Entry, Set}
    MatchingEntries(entries = Dict()) = new(entries)
end

type Response
    categories::Dict{Symbol, MatchingEntries}
    Response(categories = Dict()) = new(categories)
end

function addentry!{T}(ents::MatchingEntries, obj::T, entry::Entry)
    push!(get!(ents.entries, entry, Set{T}()), obj)
end

function addentry!{C}(response::Response, obj, entry::Entry{C})
    addentry!(get!(response.categories, C, MatchingEntries()), obj, entry)
end

# Return the set of submodules of the given `modules` that are documented.
function documented(modules::Module... = Main)
    out = Set{Module}()
    for md in modules
        for name in names(md, true)
            isdefined(md, name) || continue
            if isa((obj = getfield(md, name);), Module) && isdocumented(obj)
                push!(out, obj)
                md == obj || union!(out, documented(obj))
            end
        end
    end
    out
end

# Methods of `f` with ordered partial match of their signature to `sig`.
function partial_signature_matching(f::Function, sig::Tuple)
    meths = Set{Method}()
    for method in f.env
        msig = method.sig
        for i = 1:length(msig)
            isequal(typeintersect(msig[1:i], sig), None) || push!(meths, method)
        end
    end
    meths
end

# Does the signature or raw docstring contain the search term `q`.
found(q::String, k, v) = contains(string(k), q) || contains(data(docs(v)), q)

# General object querying.
function _query!(res, mods, cats, object)
    for m in mods
        ents = entries(documentation(m))
        haskey(ents, object) && addentry!(res, object, ents[object])
        if isa(object, Function)
            for method in object.env
                haskey(ents, method) && addentry!(res, method, ents[method])
            end
        end   
    end
    res
end

# Partial method signature queries. Use `@query <methodcall(args...)>` for exact matches.
function _query!(res, mods, cats, f::Function, sig::Tuple)
    meths = partial_signature_matching(f, sig)
    for m in mods
        ents = entries(documentation(m))
        for meth in meths
            haskey(ents, meth) && addentry!(res, meth, ents[meth])
        end
    end
    res
end

# Text search of signatures and contents of docstring. Filter by category.
function _query!(res, mods, cats, q::String)
    for m in mods
        ents = entries(documentation(m))
        for (k, v) in ents
            if (isempty(cats) || category(v) in cats) && found(q, k, v)
                addentry!(res, k, v)
            end
        end
    end
    res
end

# Module-qualified object querying. For macros and globals.
function _query!(res, mods, cats, q, modules::Module...)
    _query!(res, documented(modules...), cats, q)    
end

@doc """

Search through loaded documentation for the query term `q`. `q` can be a
`String`, for full text searches, or an object such as a function or
type. When searching for macros, methods, or globals use the provided
`@query` macro instead.

The search can be restricted to particular modules by listing them
after the search term `q`.

**Examples:**

Functions and their associated methods can be displayed by passing the function as the
first argument to query.

```julia
query(query)
```

The search can be restricted to only methods whose signatures match a given tuple. The
following `query` call will show all `query` methods where the type signature *begins*
with `String`. For exact matching of methods see the `@query` macro.

```julia
query(query, (String,))
```

To display documentation for the type `Lexicon.Summary`:

```julia
query(Lexicon.Summary)
```

Querying can be narrowed down by providing a module or modules to
search through (defaults to searching `Main`).

`categories` further narrows down the types of results returned. Choices
for this are `:method`, `:global`, `:function`, `:macro`, `:module`, and
`:type`. These options only apply to text searches such as the following:

```julia
query("Examples", Lexicon; categories = [:method, :macro])
```

The previous example displays all method and macro documentation in the `Lexicon` module
containing the text "Examples".


""" ->
function query(args...; categories = Symbol[])
    _query!(Response(), documented(), categories, args...)    
end

@doc """

Search through documentation of a particular package or globally.
`@query` supports every type of object that *Docile.jl* can document
with `@doc`.

Qualifying searches with a module identifier narrows the searching to
only the specified module. When no module is provided every loaded module
containing docstrings is searched.

**Examples:**

In a similar way to `Base.@which` you can use `@query` to search for the
documentation of a method that would be called with the given arguments.

```julia
@query query("Examples", Main)
@query Lexicon.doctest(Lexicon)
```

Full text searching is provided and looks through all text and code in docstrings, thus
behaving in a similar way to `Base.apropos`. To specify the module(s) to search through
rather use the `query` method directly.

```julia
@query "Examples"
```

Generic functions and types are supported directly by `@query`. As with
method searches the module may be specified.

```julia
@query query
@query Lexicon.query
@query Lexicon.Summary
```

Globals require a prefix argument `global` to avoid conflicting with
function/type queries as see above.

```julia
@query global Lexicon.METADATA # this won't show anything
```

""" ->
macro query(q)
    Expr(:call, :query, map(esc, parsequery(q))...)
end

function parsequery(q)
    if isa(q, Union(String, Symbol)) || isexpr(q, :(.))
        (q,)
    elseif isexpr(q, [:macrocall, :global])
        if isexpr((ex = q.args[1];), :(.))
            (Expr(:quote, ex.args[end].args[end]), ex.args[1])
        else
            (Expr(:quote, ex),)
        end
    elseif isexpr(q, :call)
        (Expr(:macrocall, symbol("@which"), q),)
    else
        error("can't recognise input.")
    end
end

@doc "Show the manual pages associated with `modname` module." ->
manual(modname::Module) = manual(documentation(modname))
