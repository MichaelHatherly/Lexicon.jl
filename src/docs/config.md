User adjustable Lexicon configuration.

#### Options

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
  `md_genindex_module_prefix = ""` if only the modulename should be displayed.
* `md_permalink`           (default: `true`):  Adds a **¶** a permalink to each definition.
  To disable it the keyword argument `md_permalink = false` should be set.

Any option can be user adjusted by passing keyword arguments to the `save` method.

**Example:** using defaults.

```julia
using Lexicon
save("docs/api/Lexicon.md", Lexicon);

```

**Example:** adjusting the initial config.

```julia
using Lexicon
config = Config(include_internal = true, md_subheader = :skip)
save("docs/api/Lexicon.md", Lexicon, config);

```
