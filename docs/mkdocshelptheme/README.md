MkDocs related example to fix the permalink below the top bannel.

See also: related MkDocs issue: https://github.com/mkdocs/mkdocs/issues/438


To test it change: `mkdocs.yml`

```yaml
site_name:           Lexicon.jl
repo_url:            https://github.com/MichaelHatherly/Lexicon.jl
site_description:    Julia package documentation generator.
site_author:         Michael Hatherly
markdown_extensions: [tables, fenced_code]
pages:
    - ['index.md', 'Introduction']
    - ['manual.md', 'Manual', 'Overview']
    - ['api/Lexicon.md', 'API', 'Lexicon']
    - ['api/genindex.md', 'API', 'Index']

theme:               bootstrap
# Example to fix the permalink below the top bannel
theme_dir:           docs/mkdocshelptheme   
```

and re-run:

```
$ mkdocs build --clean
```
