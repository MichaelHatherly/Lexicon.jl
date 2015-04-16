Saves a final *API-Index Page* to the specified `file`.
The format is guessed from the file's extension. Currently supported formats are `markdown`.

**Note:**

The `API-Index` includes all `modules` previously saved with `save` function where the option
`md_genindex = true` was set. (default)
The `savegenindex` function clears afterwards any previously collected data.

**Arguments**

* `file`: Write the *API-Index* previously generated with calls to the `save` function to the
  specified `file`. The format must be the same as the one used for the files in the `save` function.
* `config`: this must be the return of a call to the `save` function.
* Optional Keyword Arguments are the same as for the function `save`. This allows to overwrite any
  `config` option for the *API-Index Page*

**Example:**

Joining multiple modules into one *API-Index Page*. There is an example in the folder
`examples/join_multiple_modules`.

```julia
using Lexicon, Docile
save("docs/api/Lexicon.md", Lexicon);
config = save("docs/api/Docile.md", Docile);
savegenindex("docs/api/genindex.md", config)

```

#### Options

The *API-Index Page* use some of the options passed to `save` function call.
For more info see the documentation for function `save`.
