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
