# Example

To join multiple modules from different packages.

This is just an example showing how multiple modules from differen packages can be joined into one
*API-Index Page*.

* It uses different grouping for the 2 packages
* It has a `mkdocs.yml` for [MkDocs](https://github.com/mkdocs/mkdocs)

This joins the API-Documentation of the related *Julia documentation packages*
[Docile](https://github.com/MichaelHatherly/Docile.jl) and
[Lexicon](https://github.com/MichaelHatherly/Lexicon.jl).


Run in this folder:

```
$ julia join_modules_api.jl
```

To check it with `MkDocs` run

```
$ mkdocs serve
```

Point a webbrowser to `http://127.0.0.1:8000/`
