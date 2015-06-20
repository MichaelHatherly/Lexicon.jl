["Rendering helpers unrelated to specific output formats."]

# Hook into Docile's docstring parsing mechanism.
parsedocs(::Format{MarkdownFormatter}, raw, mod, obj) = Markdown.parse(raw)
