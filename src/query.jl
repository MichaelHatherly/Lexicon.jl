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

found(q, k, v)         = q == k
found(q::String, k, v) = contains(string(k), q) || contains(docs(v), q)

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

To display the documentation for a function, but not the associated
methods use `all = false` as a keyword to `query`.

```julia
query(query; all = false)
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

""" {
    :returns => (Entries,)
    } ->
function query(q, modules... = Main; categories = Symbol[], all = true)
    ents = Entries()
    for m in union([documented(m) for m in modules]...)
        for (k, v) in entries(documentation(m))
            if (isempty(categories) || category(v) in categories) && found(q, k, v)
                push!(ents, m, k, v)

                # Show methods of a generic function. TODO: Optional?
                if isa(q, Function) && all
                    for mt in q.env
                        if haskey(entries(documentation(m)), mt)
                            push!(ents, m, mt, entries(documentation(m))[mt])
                        end
                    end
                end
            end
        end
    end
    ents
end

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
    Expr(:call, query, map(esc, parsequery(q))...)
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
