# Example

To show how one could use the anchor classes: `lexicon_definition` to fix the headers
permalink with MkDocs bootstrap themes.

Include an css which fixes the paralink location below the top bannel.
see. inlcuded `extra.css`

* It has a `mkdocs.yml` for [MkDocs](https://github.com/mkdocs/mkdocs)

This joins the API-Documentation of the related *Julia documentation packages*
[Docile](https://github.com/MichaelHatherly/Docile.jl) and
[Lexicon](https://github.com/MichaelHatherly/Lexicon.jl).


Run in this folder:

```
$ julia fixheader_css_mkdocs.jl
```

To check it with `MkDocs` run

```
$ mkdocs serve
```

Point a webbrowser to `http://127.0.0.1:8000/`
