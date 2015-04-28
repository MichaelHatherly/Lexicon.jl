Write the documentation stored in `modulename` to the specified `file`.
The format is guessed from the file's extension. Currently supported formats are `HTML` and
`markdown`.

**Example:**

```julia
using Lexicon
save("docs/api/Lexicon.md", Lexicon);

```

```julia
using Lexicon, Docile, Docile.Interface
index  = Index()
update!(index, save("docs/api/Lexicon.md", Lexicon));
update!(index, save("docs/api/Docile.md", Docile));
update!(index, save("docs/api/Docile.Interface.md", Docile.Interface));
# save a joined Reference-Index
save("docs/api/api-index.md", index);

```

##### Markdown html anchor

Html anchors are inserted for each definition inclusive header and grouped sections. 
Additional to the `id` tag the same lexicon class tag is inserted `class="lexicon_definition".`

##### Sorting

The object definitions are grouped and sorted according to the `Config category_order` the modules
documentation was saved with.
This is true even when no subheader was specified: `Config md_subheader=:skip`.

**Example**

```julia
using Lexicon
config = Config(category_order = [:method, :macro], md_subheader = :skip, include_internal = true)
save("docs/api/Lexicon.md", Lexicon, config);

```

In this case there want be any Section Group subheaders but the entries will be:

* First all methods in sorted order
* Second all macros in sorted order

```julia
using Lexicon
config = Config(category_order = [:method, :macro], md_subheader = :simple, include_internal = true)
save("docs/api/Lexicon.md", Lexicon, config);

```

In this case there will be Section Group subheaders "Exported" and "Internal" (if they have items)


Section "Exported"

* First all exported methods in sorted order
* Second all exported macros in sorted order

Section "Internal"

* First all internal methods in sorted order
* Second all internal macros in sorted order

```julia
using Lexicon
config = Config(category_order = [:method, :macro], md_subheader = :split_category, include_internal = true)
save("docs/api/Lexicon.md", Lexicon, config);

```

Section "Methods [Exported]"

* Exported methods in sorted order

Section "Macros [Exported]"

* Exported macro in sorted order

Section "Methods [Interal]"

* Internal methods in sorted order

Section "Macros [Interal]"

* Interal macro in sorted order

```julia
using Lexicon
config = Config(category_order = [:method, :macro], md_subheader = :category, include_internal = true)
save("docs/api/Lexicon.md", Lexicon, config);

```

Section "Methods"

* All methods in sorted order

Section "Macros"

* All macro in sorted order


**In simple terms**

###### `md_subheader = :skip` and `md_subheader = :category`

* All per group in sorted order

  only `skip` does not display any Section subheader

###### `md_subheader = :simple` and `md_subheader = :split_category`

* First all *exported* per group in sorted order
* Second all *internal* per group in sorted order

  only `the kind of Section Subheader` differ

##### MkDocs

Beginning with Lexicon 0.1 you can save documentation as pre-formatted markdown files which can
then be post-processed using 3rd-party programs such as the static site
generator [MkDocs](http://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their detailed guides and the
Docile and Lexicon packages. A more customized build process can be found in the Sims.jl package.

Seealso [Projects using Docile / Lexicon](https://github.com/MichaelHatherly/Docile.jl#projects-using-docile--lexicon)

**Example:**

The documentation for this package can be created in the following manner. All
commands are run from the top-level folder in the package.

```julia
using Lexicon
index = save("docs/api/Lexicon.md", Lexicon);
save("docs/api/index.md", Index([index]); md_subheader = :category);
run(`mkdocs build`)

```

From the command line, or using `run`, push the `doc/site` directory to the
`gh-pages` branch on the package repository after pushing the changes to the
`master` branch.

```
git add .
git commit -m "documentation changes"
git push origin master
git subtree push --prefix site origin gh-pages

```

One can also use the MkDocs option `gh-deploy` - consult their guides.

```julia
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
