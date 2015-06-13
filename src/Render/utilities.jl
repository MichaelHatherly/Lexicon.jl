["Rendering helpers unrelated to specific output formats."]

# Hook into Docile's docstring parsing mechanism.
parsedocs(::Format{MarkdownFormatter}, raw, mod, obj) = Markdown.parse(raw)

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
