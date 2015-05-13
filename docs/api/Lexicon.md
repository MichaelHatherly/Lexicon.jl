# Lexicon

## Exported

---

<a id="method__doctest.1" class="lexicon_definition"></a>
#### doctest(modname::Module) [¶](#method__doctest.1)
Run code blocks in the docstrings of the specified module `modname`.
Returns a `Summary` of the results.

Code blocks may be skipped by adding an extra newline at the end of the block.

**Example:**

```julia_skip
doctest(Lexicon)
```


*source:*
[Lexicon/src/doctest.jl:100](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/doctest.jl#L100)

---

<a id="method__query.1" class="lexicon_definition"></a>
#### query(f::Function, sig) [¶](#method__query.1)
Search loaded documentation for methods of generic function `f` that match `sig`.
Optionally, provide an index (1-based) to view an individual entry if several different ones are
found.


*source:*
[Lexicon/src/query.jl:157](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L157)

---

<a id="method__query.2" class="lexicon_definition"></a>
#### query(f::Function, sig, index) [¶](#method__query.2)
Search loaded documentation for methods of generic function `f` that match `sig`.
Optionally, provide an index (1-based) to view an individual entry if several different ones are
found.


*source:*
[Lexicon/src/query.jl:157](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L157)

---

<a id="method__save.1" class="lexicon_definition"></a>
#### save(file::AbstractString, index::Lexicon.Index, config::Lexicon.Config) [¶](#method__save.1)
Saves an *API-Index* to `file`.


*source:*
[Lexicon/src/render.jl:173](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/render.jl#L173)

---

<a id="method__save.2" class="lexicon_definition"></a>
#### save(file::AbstractString, modulename::Module, config::Lexicon.Config) [¶](#method__save.2)
Write the documentation stored in `modulename` to the specified `file`.
The format is guessed from the file's extension. Currently supported formats are `HTML` and
`markdown`.

**Example:**

```julia_skip
using Lexicon
save("docs/api/Lexicon.md", Lexicon);
```

```julia_skip
using Lexicon, Docile, Docile.Interface
index  = Index()
update!(index, save("docs/api/Lexicon.md", Lexicon));
update!(index, save("docs/api/Docile.md", Docile));
update!(index, save("docs/api/Docile.Interface.md", Docile.Interface));
# save a joined Reference-Index
save("docs/api/api-index.md", index);
```

#### MkDocs

Beginning with Lexicon 0.1 you can save documentation as pre-formatted markdown files which can
then be post-processed using 3rd-party programs such as the static site
generator [MkDocs](http://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their detailed guides and the
Docile and Lexicon packages. A more customized build process can be found in the Sims.jl package.

Seealso [Projects using Docile / Lexicon](https://github.com/MichaelHatherly/Docile.jl#projects-using-docile--lexicon)

**Example:**

The documentation for this package can be created in the following manner. All
commands are run from the top-level folder in the package.

```julia_skip
using Lexicon
index = save("docs/api/Lexicon.md", Lexicon);
save("docs/api/index.md", Index([index]); md_subheader = :category);
run(`mkdocs build`)
```

From the command line, or using `run`, push the `doc/site` directory to the
`gh-pages` branch on the package repository after pushing the changes to the
`master` branch.

```bash
git add .
git commit -m "documentation changes"
git push origin master
git subtree push --prefix site origin gh-pages
```

One can also use the MkDocs option `gh-deploy` - consult their guides.

```julia_skip
using Lexicon
index = save("docs/api/Lexicon.md", Lexicon);
save("docs/api/index.md", Index([index]); md_subheader = :category);
run(`mkdocs gh-deploy --clean`)
```

If this is the first push to the branch then the site may take some time to
become available. Subsequent updates should appear immediately. Only the
contents of the `doc/site` folder will be pushed to the branch.

The documentation will be available from
`https://USER_NAME.github.io/PACKAGE_NAME/FILE_PATH.html`.


*source:*
[Lexicon/src/render.jl:162](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/render.jl#L162)

---

<a id="type__config.1" class="lexicon_definition"></a>
#### Lexicon.Config [¶](#type__config.1)
User adjustable Lexicon configuration.

#### Options

*General Options*

* `category_order` (default: `[:module, :function, :method, :type, :typealias, :macro, :global, :comment]`)
  Categories  to include in the output in the defined order.
* `include_internal` (default: `true`): To exclude documentation for non-exported objects,
  the keyword argument `include_internal = false` should be set. This is only supported for
  `markdown`.
* `metadata_order`      (default: `[:source]`)
  Metadata to include in the output in the defined order. To not output any metadate
  `metadata_order = Symbol[]` should be set.

*HTML only options*

* `mathjax` (default: `false`): If MathJax support is required then the optional keyword
  argument `mathjax = true` can be given to the `save` method.
  MathJax uses `\(...\)` for in-line maths and `\[...\]` or `$$...$$` for display equations.

*Markdown only options*

Valid values for the `mdstyle_*` options listed below are either 1 to 6 `#`
characters or 0 to 2 `*` characters.

* `mdstyle_header`         (default: `"#"`):   style for the documentation header and *API-Index*
  modules header.
* `mdstyle_objname`        (default: `"####"`): style for each documented object.
* `mdstyle_meta`           (default: `"*"`):   style for the metadata section on each
  documentation entry.
* `mdstyle_subheader`      (default: `"##"`):  style for the documentation and *API-Index* subheader.
* `mdstyle_index_mod`      (default: `"##"`):  style for the *API-Index* module header.

* `md_subheader`           (default: `:simple`): Valid options are ":skip, :simple, :category"

    * `md_subheader=:simple`   adds documentation and *API-Index* subheaders "Exported" / "Internal".
    * `md_subheader=:category` adds documentation and *API-Index* subheaders per category.
    * `md_subheader=:skip`     adds no subheaders to the documentation and *API-Index* and can be used
    for documentation which has only few entries.

* `md_index_modprefix`     (default: `"MODULE: "`): This option sets for the *API-Index Page*
  a "prefix" text before the modulename.
  `md_genindex_module_prefix = ""` if only the modulename should be displayed.
* `md_permalink`           (default: `true`):  Adds a **¶** a permalink to each definition.
  To disable it the keyword argument `md_permalink = false` should be set.

Any option can be user adjusted by passing keyword arguments to the `save` method.


#### Config Usage

There are 3 ways to define user adjusted configuration settings.

**Config**

```julia_skip
using Lexicon

# get default `Config`
config = Config()

# get a new adjusted `Config`
config = Config(md_permalink = false, mathjax = true)
```

**Document `save` method**

The document `save` method accepts also a 'Config' as argument or supplies internaly a default one.
Similar to the above 'Config usage' one can also pass otional `args...` which will overwrite a
deepcopy of config but not change config itself.
This allows using the same base configuration settings multiple times.

```julia_skip
using Lexicon

# 1. get a new adjusted `Config`
config = Config(md_permalink = false, mathjax = true)

# 2.using the adjusted `Config`
save("docs/api/Lexicon.md", Lexicon, config);

# 3.overwrite a deepcopy of `config`
save("docs/api/Lexicon.md", Lexicon, config; md_permalink = true);

# 4. This uses the same configuration as set in '1.' (md_permalink is still `false`)
save("docs/api/Lexicon.md", Lexicon, config);
```

The document `save` also supplies a default 'Config'.

```julia_skip
using Lexicon

# 1. using the default supplied Config of method `save`
save("docs/api/Lexicon.md", Lexicon);

# 2. this is the same as '1.'
config = Config()
save("docs/api/Lexicon.md", Lexicon, config);
```

The next three examples are all using the same configuration to save *Lexicon*

```julia_skip
using Lexicon

# 1.
config = Config(md_permalink = false, mathjax = true)
save("docs/api/Lexicon.md", Lexicon, config);

# 2.
config = Config()
save("docs/api/Lexicon.md", Lexicon, config; md_permalink = false, mathjax = true);

# 3.
save("docs/api/Lexicon.md", Lexicon; md_permalink = false, mathjax = true);
```

**API-Index `save` method**

The *API-Index* `save` method works similar to the above *Document `save` method*


*source:*
[Lexicon/src/render.jl:11](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/render.jl#L11)

---

<a id="type__eachentry.1" class="lexicon_definition"></a>
#### Lexicon.EachEntry [¶](#type__eachentry.1)
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



*source:*
[Lexicon/src/filtering.jl:127](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/filtering.jl#L127)

---

<a id="macro___query.1" class="lexicon_definition"></a>
#### @query(args...) [¶](#macro___query.1)
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


*source:*
[Lexicon/src/query.jl:98](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L98)

## Internal

---

<a id="method__calculate_score.1" class="lexicon_definition"></a>
#### calculate_score(query, text, object) [¶](#method__calculate_score.1)
Basic text importance scoring.

*source:*
[Lexicon/src/query.jl:178](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L178)

---

<a id="method__call.1" class="lexicon_definition"></a>
#### call(::Type{Lexicon.Config}) [¶](#method__call.1)
Returns a default Config. If any args... are given these will overwrite the defaults.

```
using Lexicon
config = Config(md_permalink = false, mathjax = true)

```


*source:*
[Lexicon/src/render.jl:50](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/render.jl#L50)

---

<a id="method__call.2" class="lexicon_definition"></a>
#### call(::Type{Lexicon.EachEntry}, docs::Docile.Legacy.Metadata) [¶](#method__call.2)
Constructor.

**Example**

```julia_skip
using Lexicon, Docile, Docile.Interface
docs = metadata(Docile);
EachEntry(docs::Metadata; order = [:category, :name, :source])
```


*source:*
[Lexicon/src/filtering.jl:143](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/filtering.jl#L143)

---

<a id="method__filter.1" class="lexicon_definition"></a>
#### filter(docs::Docile.Legacy.Metadata) [¶](#method__filter.1)
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



*source:*
[Lexicon/src/filtering.jl:40](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/filtering.jl#L40)

---

<a id="method__filter.2" class="lexicon_definition"></a>
#### filter(f::Function, docs::Docile.Legacy.Metadata) [¶](#method__filter.2)
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



*source:*
[Lexicon/src/filtering.jl:77](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/filtering.jl#L77)

---

<a id="type__match.1" class="lexicon_definition"></a>
#### Lexicon.Match [¶](#type__match.1)
An entry and the set of all objects that are linked to it.

*source:*
[Lexicon/src/query.jl:32](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L32)

---

<a id="type__query.1" class="lexicon_definition"></a>
#### Lexicon.Query [¶](#type__query.1)
Holds the parsed user query.

**Fields:**

* `objects`: The objects that will be searched for in metadata.
* `mods`:    Modules to be searched through for documentation.
* `index`:   1-based, for picking an individual entry to display out of a list.


*source:*
[Lexicon/src/query.jl:13](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L13)

---

<a id="type__queryresults.1" class="lexicon_definition"></a>
#### Lexicon.QueryResults [¶](#type__queryresults.1)
Stores the matching entries resulting from running a query.

*source:*
[Lexicon/src/query.jl:42](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L42)

---

<a id="typealias__queryable.1" class="lexicon_definition"></a>
#### Queryable [¶](#typealias__queryable.1)
Types that can be queried.

*source:*
[Lexicon/src/query.jl:2](https://github.com/MichaelHatherly/Lexicon.jl/tree/f0264227542d3fcfd3b07a1531debb646a1d1999/src/query.jl#L2)

