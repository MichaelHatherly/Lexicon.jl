# Automatic parsing of plain text in nodes.
parsetext(::Format, raw) = raw
parsetext(::Format{MarkdownFormatter}, raw) = Markdown.parse(raw)

function readtext(formatter::Format, node::Node, text)
    d = Elements.findconfig(node, :rootdir, UTF8String)
    dir = isnull(d) ? pwd() : get(d)
    file = joinpath(dir, text)
    (length(file) < 256 && isfile(file)) && (text = readall(file))
    parsetext(formatter, text)
end
