User adjustable Lexicon configuration.

##### Options

*General Options*

* `category_order` (default: `[:module, :function, :method, :type, :typealias, :macro, :global, :comment]`)
  Categories  to include in the output in the defined order.
* `include_internal` (default: `true`): To exclude documentation for non-exported objects,
  the keyword argument `include_internal = false` should be set. This is only supported for
  `markdown`.

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
  `md_index_modprefix = ""` if only the modulename should be displayed. This must be passed to the 
  `Index save method`.
* `md_index_grpsection`    (default: `true`):  `md_index_grpsection = true` will add to the
  *API-Index Page* a Section with links to the module's group subheader sections. This must be passed
  to the `Index save method`.

* `md_permalink`           (default: `true`):  Adds a **¶** a permalink to each definition.
  To disable it the keyword argument `md_permalink = false` should be set.
* `md_grp_permalink`       (default: `false`):  Adds a **¶** a permalink to each group section.
  Subheaders "Exported" / "Internal" or subheaders per category.

Any option can be user adjusted by passing keyword arguments to the `save` method.


##### Config Usage

There are 3 ways to define user adjusted configuration settings.

*1. Config*

```julia
using Lexicon

# get default `Config`
config = Config()

# get a new adjusted `Config`
config = Config(md_permalink = false, mathjax = true)

```

*2. Document `save` method*

The document `save` method accepts also a 'Config' as argument or supplies internaly a default one.
Similar to the above 'Config usage' one can also pass otional `args...` which will overwrite a
deepcopy of config but not change config itself.
This allows using the same base configuration settings multiple times.

```julia
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

```julia
using Lexicon

# 1. using the default supplied Config of method `save`
save("docs/api/Lexicon.md", Lexicon);

# 2. this is the same as '1.'
config = Config()
save("docs/api/Lexicon.md", Lexicon, config);

```

The next three examples are all using the same configuration to save *Lexicon*

```julia
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


*3. API-Index `save` method*

The configuration settings for the *API-Index* `save` method works similar to the above
*Document `save` method*

```
using Lexicon
index = Index([save("docs/api/Lexicon.md", Lexicon)]);

# 1.
config = Config(md_subheader = :category)
save("docs/api/index.md", index, config);

# 2. using the default supplied Config
save("docs/api/index.md", index; md_subheader = :category);

# 3. using all defaults
save("docs/api/index.md", index);

```
