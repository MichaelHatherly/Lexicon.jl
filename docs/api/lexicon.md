# Lexicon

## Exported
---

#### doctest(modname::Module)
Run code blocks in the docstrings of the specified module `modname` and return
a `Summary` of the results.

Code blocks may be skipped by adding an extra newline at the end of the block.

**Example:**

```julia
doctest(Lexicon)

```


**source:**
[Lexicon/src/doctest.jl:101](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/doctest.jl#L101)

---

#### query(f::Function, sig::(Any..., ))
Search loaded documentation for all methods of a generic function `f` that match
the provided signature `sig`. Optionally, provide an index (1-based) to view an
individual entry if several different ones are found.


**source:**
[Lexicon/src/query.jl:219](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L219)

---

#### query(f::Function, sig::(Any..., ), index)
Search loaded documentation for all methods of a generic function `f` that match
the provided signature `sig`. Optionally, provide an index (1-based) to view an
individual entry if several different ones are found.


**source:**
[Lexicon/src/query.jl:219](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L219)

---

#### save(file::String, modulename::Module)
Write the documentation stored in `modulename` to the specified `file`
in the format guessed from the file's extension.

If MathJax support is required then the optional keyword argument
`mathjax::Bool` may be given. MathJax uses `\(...\)` for in-line maths
and `\[...\]` or `$$...$$` for display equations.

Currently supported formats: `HTML`, and `markdown`.

**MkDocs**

Beginning with Lexicon 0.1 you can save documentation as pre-formatted
markdown files which can then be post-processed using 3rd-party programs
such as the static site generator [MkDocs](https://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their
detailed guides and the Docile and Lexicon packages. A more customized build
process can be found in the Sims.jl package.

**Example:**

The documentation for this package was created in the following manner.
All commands are run from the top-level folder in the package.

```julia
save("docs/api/lexicon.md", Lexicon)
run(`mkdocs build`)

```

From the command line, or using `run`, push the `doc/site` directory
to the `gh-pages` branch on the package repository after pushing the
changes to the `master` branch.

```
git add .
git commit -m "documentation changes"
git push origin master
git subtree push --prefix docs/build origin gh-pages

```

If this is the first push to the branch then the site may take some time
to become available. Subsequent updates should appear immediately. Only
the contents of the `doc/site` folder will be pushed to the branch.

The documentation will be available from
`https://USER_NAME.github.io/PACKAGE_NAME/FILE_PATH.html`.



**source:**
[Lexicon/src/render.jl:58](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/render.jl#L58)

---

#### EachEntry
Iterator type for Metadata Entries with sorting options

**Constructors**

```julia
EachEntry(docs::Metadata; order = [:category, :name, :source])
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



**source:**
[Lexicon/src/filtering.jl:138](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/filtering.jl#L138)

---

#### @query(args...)
Search through documentation of a particular package or globally. `@query`
supports every type of object that *Docile.jl* can document with `@doc`.

**Note:** the functionality provided by `@query` is also available using `?` at
the Julia REPL. It displays documentation from the standard Julia help system
followed by package documentation from Docile.

Qualifying searches with a module identifier narrows the searching to only the
specified module. When no module is provided every loaded module containing
docstrings is searched.

**Examples:**

In a similar way to `Base.@which` you can use `@query` to search for the
documentation of a method that would be called with the given arguments.

```julia
@query save("api/lexicon.md", Lexicon)
@query Lexicon.doctest(Lexicon)
```

Full text searching is provided and looks through all text and code in
docstrings, thus behaving in a similar way to `Base.apropos`.

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

Searching for documented constants is also supported:

```julia
@query Lexicon.__METADATA__ # this won't show anything
```

**Selecting individual results**

When several results are found for a given query only the signature of each is
displayed in the REPL. The signatures are numbered starting from `1`. To view
the full documentation for a particular signature listed rerun the previous
query with the index of the desired signature as an additional argument.

(Pressing the up arrow is the simplest way to get back to the previous query.)

**Example:**

```julia
julia> foobar

  1: foobar
  2: foobar(x)
  3: foobar(x, y)

julia> foobar 2

# docs for `foobar(x)` are displayed now.
```


**signature:**
query(args...)

**source:**
[Lexicon/src/query.jl:151](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L151)

## Internal
---

#### calculate_score(query, text, object)
Basic text importance scoring.

**source:**
[Lexicon/src/query.jl:242](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L242)

---

#### filter(docs::Metadata)
Filter Metadata based on categories or file source

```julia
Base.filter(docs::Metadata; categories = Symbol[], files = String[])
```

**Arguments**

* `docs` : main input

**Optional keyword arguments**

* `categories` : categories to include in the result; can include any
  of [:module, :function, :method, :type, :macro, :global, :comment];
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



**source:**
[Lexicon/src/filtering.jl:43](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/filtering.jl#L43)

---

#### filter(f::Function, docs::Metadata)
Filter Metadata based on a function

```julia
Base.filter(f::Function, docs::Metadata)
```

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



**source:**
[Lexicon/src/filtering.jl:86](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/filtering.jl#L86)

---

#### Match
An entry and the set of all objects that are linked to it.

**source:**
[Lexicon/src/query.jl:43](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L43)

---

#### Query
Holds the parsed user query.

**Fields:**

* `objects`: The objects that will be searched for in metadata.
* `mods`:    Modules to be searched through for documentation.
* `index`:   1-based, for picking an individual entry to display out of a list.



**source:**
[Lexicon/src/query.jl:23](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L23)

---

#### QueryResults
Stores the matching entries resulting from running a query.

**source:**
[Lexicon/src/query.jl:53](https://github.com/MichaelHatherly/Lexicon.jl/tree/ef3170f9e98997e5884e2ffba00772be679e852f/src/query.jl#L53)


