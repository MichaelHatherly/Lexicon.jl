### Viewing Documentation

Lexicon hooks into the REPL's `?` mode (help-mode) once `using Lexicon` has been
called from the REPL. Other environments, such as editors, are not currently
supported.

When searching for documentation press `?` to entry the help mode.

Lexicon supports searching for functions, methods, macros, constants, modules,
types, and plain text.

**Examples:**

Searching for a `Function` named `foobar` will show a list of documentation
associated with it and any of it's `Method`s that are also documented.

```julia
help?> foobar

  1: foobar
  2: foobar(x)
  3: foobar(x, y)

```

To view the documentation for a specific entry rerun the previous query, using
the up arrow to go back to the previously entered command, and append the index
you would like to display.

```julia
help?> foobar 2

  # Docstring for `foobar(x)` ...

```

To display the documentation for `foobar(x)` directly use:

```julia
help?> foobar("some value")

  # Docstring for `foobar(x)` ...

```

To perform a full text search of all currently loaded modules use double quotes:

```julia
help?> "foobar"

  # List of results matching the search term "foobar" ...

```

Searching for macros, types, and constants works in the same way as for
functions.

To only search a specific module use the usual dot syntax:

```julia
help?> Foobar.baz

  # List of results matching `baz` in module `Foobar`.

```

### Generating Documentation

Documentation may be exported using the provided `save` function. It currently
supports HTML and markdown output which can be hosted on a package's `gh-pages`
branch or any other hosting service. See the documentation for `save` for
further details.

### Doctests

*Lexicon.jl* includes a `doctest` function that runs code blocks in docstrings
and generates summaries of the results. Code blocks can be skipped by adding an
extra new line at the end of the block.
