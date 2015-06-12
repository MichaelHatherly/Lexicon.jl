["Rendering helpers unrelated to specific output formats."]

# Hook into Docile's docstring parsing mechanism.
parsedocs(::Format{MarkdownFormatter}, raw, mod, obj) = Markdown.parse(raw)

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

# Symbolic names. #

name(mod, m::Method) = m.func.code.name

name(mod, m::Module) = module_name(m)

name(mod, t::DataType) = t.name.name

function name(mod, obj::Function)
    meta = Cache.getmeta(mod, obj)
    if meta[:category] == :macro
        symbol(string("@", meta[:signature].args[1]))
    else
        obj.env.name
    end
end

name(mod, q::QualifiedSymbol) = q.sym

function name(mod, obj::Aside)
    linenumber, path = Cache.getmeta(mod, obj)[:textsource]
    return symbol("aside_$(first(splitext(basename(path))))_L$(linenumber)")
end
