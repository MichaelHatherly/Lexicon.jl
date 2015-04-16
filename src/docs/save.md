Write the documentation stored in `modulename` to the specified `file`.
The format is guessed from the file's extension. Currently supported formats are `HTML` and
`markdown`.

**Returns**

* `::Config` : the configuration which can be used as input argument to the related `savegenindex`
  function.

#### Options

*General Options*

* `category_order` (default: `:module, :function, :method, :type, :typealias, :macro, :global, :comment`)
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
* `mdstyle_genindex_mod`   (default: `"##"`):  style for the *API-Index* module header.

* `md_subheader`           (default: `:SIMPLE`): Valid options are ":SKIP, :SIMPLE, :CATEGORY"

  * `md_subheader=:SIMPLE`   adds documentation and *API-Index* subheaders "Exported" / "Internal".
  * `md_subheader=:CATEGORY` adds documentation and *API-Index* subheaders per category.
  * `md_subheader=:SKIP`     adds no subheaders to the documentation and *API-Index* and can be used
    for documentation which has only few entries.

* `md_genindex`            (default: `true`):  To disable markdown *API-Index Page* generation
  the keyword argument `md_genindex = false` should be set.
  To actually save the *API-Index* one has to use the `savegenindex` function.
* `md_genindex_modprefix`  (default: `"MODULE: "`): This option sets for the *API-Index Page*
  a "prefix" text before the modulename.
  `md_genindex_module_prefix = ""` if only the modulename should be displayed.
* `md_permalink`           (default: `true`):  Adds a **¶** a permalink to each definition.
  To disable it the keyword argument `md_permalink = false` should be set.

Any option can be user adjusted by passing keyword arguments to the `save` method.

**Example:**

```julia
using Lexicon
save("Lexicon.md", Lexicon; include_internal = false, mdstyle_header = "###");

```

#### Optional Html Anchors

If either option `md_genindex` or `md_permalink` is set to  `true`, an additional html anchor
is added to to each definition.
All html anchir have an additional class attribute called: `lexicon_definition`.
This can be used in specific cases to adjust html pages output.
(e.g. generated with MkDocs' bootstrap themes when the mdstyle is bold or italic)

There is an example in the folder `examples/fixheader_css_mkdocs`.

#### MkDocs

Beginning with Lexicon 0.1 you can save documentation as pre-formatted markdown
files which can then be post-processed using 3rd-party programs such as the
static site generator [MkDocs](http://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their
detailed guides and the Docile and Lexicon packages. A more customized build
process can be found in the Sims.jl package.

**Example:**

The documentation for this package can be created in the following manner. All commands are run
from the top-level folder in the package.

```julia
using Lexicon
save("docs/api/Lexicon.md", Lexicon);
run(`mkdocs build`)

```

There is also a `docs/build.jl` which can be run with `julia docs/build.jl`
From the command line, or using `run`, push the `docs/site` directory to the `gh-pages` branch on the
package repository after pushing the changes to the `master` branch. If using MkDocs see also the
option `gh-deploy`.

```
git add .
git commit -m "documentation changes"
git push origin master
git subtree push --prefix docs/build origin gh-pages

```

If this is the first push to the branch then the site may take some time to
become available. Subsequent updates should appear immediately. Only the
contents of the `doc/site` folder will be pushed to the branch.

The documentation will be available from
`https://USER_NAME.github.io/PACKAGE_NAME/FILE_PATH.html`.
