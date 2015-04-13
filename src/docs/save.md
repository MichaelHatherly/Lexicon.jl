Write the documentation stored in `modulename` to the specified `file`.
The format is guessed from the file's extension. Currently supported formats
are `HTML` and `markdown`.

#### Options

*General Options*

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

* `mdstyle_header`   (default: `"#"`):   style for the documentation header.
* `mdstyle_objname`  (default: `"###"`): style for each documented object.
* `mdstyle_meta`     (default: `"*"`):   style for the metadata section on each documentation entry.
* `mdstyle_exported` (default: `"##"`):  style for the "exported" documentation header.
* `mdstyle_internal` (default: "##"):    style for the "internal" documentation header.

* `md_genindex`      (default: `true`):  to disable markdown *API-Index Page* generation
  the keyword argument `md_genindex = false` should be set.
  To actually save the *API-Index* one has to use the `savegenindex` function.

Any option can be user adjusted by passing keyword arguments to the `save` method.

**Example:**

```julia
using Lexicon
save("Lexicon.md", Lexicon; include_internal = false, mdstyle_header = "###")

```

#### MkDocs

Beginning with Lexicon 0.1 you can save documentation as pre-formatted markdown
files which can then be post-processed using 3rd-party programs such as the
static site generator [MkDocs](http://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their
detailed guides and the Docile and Lexicon packages. A more customized build
process can be found in the Sims.jl package.

**Example:**

The documentation for this package was created in the following manner. All
commands are run from the top-level folder in the package.

```julia
using Lexicon
save("docs/api/Lexicon.md", Lexicon)
run(`mkdocs build`)

```

From the command line, or using `run`, push the `doc/site` directory to the
`gh-pages` branch on the package repository after pushing the changes to the
`master` branch.

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
