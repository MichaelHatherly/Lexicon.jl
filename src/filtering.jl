## Various methods for filtering and sorting Metadata

const CATEGORY_ORDER = [:module, :function, :method, :type, :typealias, :macro, :global]

"""
Filter Metadata based on categories or file source.

**Arguments**

* `docs` : main input

**Optional keyword arguments**

* `categories` : categories to include in the result; can include any
  of [:module, :function, :method, :type, :typealias, :macro, :global, :comment];
  defaults to all but :comment

* `files` : vector of file names where entries originated to include
  in the result; full pathnames are searched; can include partial
  paths; defaults to all

**Returns**

* `::Metadata` : the filtered result

**Example**

```julia
using Lexicon, Docile, Docile.Interface
d = metadata(Docile);

# Filter entries with categories of :macro and :type
entries( filter(d, categories = [:macro, :type]) )

# Filter entries from the file types.jl
entries( filter(d, files = ["types.jl"]) )
```

"""
function Base.filter(docs::Metadata; categories = CATEGORY_ORDER, files = String[])
    result = copy(docs)
    if length(files) > 0
        filter!((k,v) -> any(x -> contains(v.data[:source][2], x), files), result.entries)
    end
    if length(categories) > 0
        filter!((k,v) -> any(x -> category(v) == x, categories), result.entries)
    end
    result
end

"""
Filter Metadata based on a function.

**Arguments**

* `f` : a function that filters Entries and returns a Bool; the
  function signature should be `f(x::Entry)`.
* `docs` : main input

**Returns**

* `::Metadata` : the filtered result

**Example**

```julia
using Lexicon, Docile, Docile.Interface
d = metadata(Docile);

# Filter entries with all categories except :type
res = filter(d) do e
    category(e) != :type
end
```

"""
function Base.filter(f::Function, docs::Metadata)
    result = copy(docs)
    filter!((k,v) -> f(v), result.entries)
    result
end


"""
Iterator type for Metadata Entries with sorting options.

**Constructors**

    EachEntry(docs::Metadata; order = [:category, :name, :source])

**Arguments**

* `docs` : main input

**Optional keyword arguments**

* `order` : indicators of sorting order, given in priority, options include:
  * `:category` - category of Entries
  * `:exported` - whether the item is exported or unexported
  * `:name` - name of Entries
  * `:source` - source location of Entries uses both the file path and
    line number

In addition to symbols, items in `order` can be functions of the form
`(x,y) = ...` where `x` is the documented item, and `y` is the
Entry. The function should return a quantity to be compared when
sorting.

**Main methods**

An iterable, supports `start`, `next`, and `done`. `next` returns a
`(key, value)` pair where the `key` is the ObjectId key, and `value`
is the Entry.

**Example**

```julia
using Lexicon, Docile, Docile.Interface
d = metadata(Docile);

# Collect the source location of each Entry sorted by the default
# (:category then :name then :source).
res = [v.data[:source][2] for (k,v) in EachEntry(d)]
```

"""
type EachEntry
    parent::Metadata
    kidx
end

"""
Constructor.

**Example**

```julia_skip
using Lexicon, Docile, Docile.Interface
docs = metadata(Docile);
EachEntry(docs::Metadata; order = [:category, :name, :source])
```
""";
function EachEntry(docs::Metadata; order = [:category, :name, :source])
    funmap = @compat Dict(:name     => (k,v) -> writeobj(k,v), # various vectors for sorting
                          :exported => (k,v) -> !exported(modulename(v), k),
                          :source   => (k,v) -> reverse(v.data[:source]),
                          :category => (k,v) -> indexin([category(v)], CATEGORY_ORDER)[1])
    funs = [isa(o, Symbol) ? funmap[o] : o for o in order]
    function lessthan(x,y)
        for f in funs
            f(x...) < f(y...) && return true
            f(x...) > f(y...) && return false
        end
        return false
    end
    idx = sortperm(collect(docs.entries), lt = lessthan)
    EachEntry(docs, collect(keys(docs.entries))[idx])
end

Base.length(x::EachEntry) = length(x.kidx)
Base.start(x::EachEntry) = 1
Base.done(x::EachEntry, state) = state == length(x.kidx)
Base.next(x::EachEntry, state) = ((x.kidx[state], x.parent.entries[x.kidx[state]]), state + 1)
