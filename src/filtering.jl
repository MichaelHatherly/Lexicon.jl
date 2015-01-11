## Various methods for filtering and sorting Documentation


"""
Filter Documentation based on categories or file source

```julia
Base.filter(docs::Documentation; categories = Symbol[], files = String[])
```

**Arguments**

* `docs` : main input

**Optional keyword arguments**

* `categories` : categories to include in the result; can include any
  of [:module, :function, :method, :type, :macro, :global]

* `files` : vector of file names where entries originated to include
  in the result; full pathnames are searched; can include partial
  paths

**Returns**

* `::Documentation` : the filtered result

**Example**

```julia
using Lexicon, Docile, Docile.Interface
d = documentation(Docile);

# Filter entries with categories of :macro and :type
entries( filter(d, categories = [:macro, :type]) )

# Filter entries from the file types.jl
entries( filter(d, files = ["types.jl"]) )
```

"""
function Base.filter(docs::Documentation; categories = Symbol[], files = String[])
    entries = copy(docs.entries)
    if length(files) > 0
        filter!((k,v) -> any(x -> contains(v.data[:source][2], x), files),
                entries)
    end
    if length(categories) > 0
        filter!((k,v) -> any(x -> category(v) == x, categories),
                entries)
    end
    Metadata(docs.modname, entries, docs.root, docs.files, docs.data, docs.loaded)
end


"""
Iterator type for Documentation Entries with sorting options

**Constructors**

```julia
EachEntry(docs::Documentation; order::Vector{Symbol} = [:category, :name, :source])
```

**Arguments**

* `docs` : main input

**Optional keyword arguments**

* `order` : indicators of sorting order, given in priority, options include:
  * `:category` - category of Entries
  * `:exported` - whether the item is exported or unexported
  * `:name` - name of Entries
  * `:source` - source location of Entries uses both the file path and
    line number

**Main methods**

An iterable, supports `start`, `next`, and `done`. `next` returns a
`(key, value)` pair where the `key` is the ObjectId key, and `value`
is the Entry.

**Example**

```julia
using Lexicon, Docile, Docile.Interface
d = documentation(Docile);

# Collect the source location of each Entry sorted by the default
# (:category then :name then :source).
res = [v.data[:source][2] for (k,v) in EachEntry(d)]
```

"""
type EachEntry
    parent::Documentation
    kidx
end


function EachEntry(docs::Documentation; order::Vector{Symbol} = [:category, :name, :source])
    ks = collect(keys(docs.entries))
    vs = collect(values(docs.entries))
    name = [writeobj(k, v) for (k, v) in docs.entries]
    source = [v.data[:source] for v in values(docs.entries)]
    category_ = [category(v) for v in values(docs.entries)]
    ## unimplemented options:
    # doctag = [isa(k, Type) && k <: DocTag for k in keys(docs.entries)]
    # unexported = [?? for k in keys(docs.entries)]
    d = [:name => name,    # various vectors for sorting
         # :doctag => !doctag,
         # :unexported => unexported,
         :source => [(a[2], a[1]) for a in source],
         :category => category_]
    idx = sortperm(collect(zip([d[o] for o in order]...)))
    EachEntry(docs, ks[idx])
end 

Base.length(x::EachEntry) = length(x.kidx)
Base.start(x::EachEntry) = 1
Base.done(x::EachEntry, state) = state == length(x.kidx)
Base.next(x::EachEntry, state) = ((x.kidx[state], x.parent.entries[x.kidx[state]]), state + 1)

## Another option to consider for sorting is to allow the user to pass
## in an anonymous function that will produce an ordering vector.
## Another option is to see if we can hook into the Base sorting
## routines to do some of this for us.
