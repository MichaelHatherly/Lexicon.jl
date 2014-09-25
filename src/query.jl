type MatchingEntries
    entries::Dict{Entry, Set}
    MatchingEntries(entries = Dict()) = new(entries)
end

category{C}(entry::Entry{C}) = C

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

function documented(md = Main)
    modules = Set{Module}()
    for name in names(md, true)
        isdefined(md, name) || continue
        if isa((obj = getfield(md, name);), Module) && isdocumented(obj)
            push!(modules, obj)
            md == obj || union!(modules, documented(obj))
        end
    end
    modules
end

found(q::String, k, v) = contains(string(k), q) || contains(data(docs(v)), q)

@doc """

Search through loaded documentation for the query term `q`. `q` can be a
`String`, for full text searches, or an object such as a function or
type. When searching for macros, methods, or globals use the provided
`@query` macro instead.

The search can be restricted to particular modules by listing them
after the search term `q`.

**Examples:**

Display documentation for the `Lexicon.Summary`:

```julia
query(Lexicon.Summary)
```

Querying can be narrowed down by providing a module or modules to
search through (defaults to searching `Main`).

`categories` further narrows down the types of results returned. Choices
for this are `:method`, `:global`, `:function`, `:macro`, `:module`, and
`:type`. These options are more useful when doing a text search rather
than an object search.

```julia
query("Examples", Lexicon; categories = [:method, :macro])
```

""" ->
function query(q, modules::Module... = Main; categories = Symbol[])
    res = Response()
    for m in union([documented(m) for m in modules]...)
        ents = entries(documentation(m))
        if isa(q, String) # text search
            for (k, v) in ents
                if (isempty(categories) || category(v) in categories) && found(q, k, v)
                    addentry!(res, k, v)
                end
            end
        else # object search
            haskey(ents, q) && addentry!(res, q, ents[q])
            if isa(q, Function)
                for method in q.env
                    haskey(ents, method) && addentry!(res, method, ents[method])
                end
            end
        end
    end
    res
end

@doc "Get documentation related to the method `q` with the given `signature`." ->
query(q::Function, signature::Tuple) = query(which(q, signature))

@doc "Search packages for *Docile.jl* generated documentation." -> query

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

Full text searching is provided and looks through all text and code in
docstrings, thus behaving in a similar way to `Base.apropos`. To specify
the module(s) to search through rather use the `query` method directly.

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
    if isa(q, Union(String, Symbol))
        (q,)
    elseif isexpr(q, :(.))
        (q, q.args[1])
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
