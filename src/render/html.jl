## Docs-specific rendering ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writehtml(io::IO, docs::Docile.Interface.Docs{:md})
    writemime(io, MIME("text/html"), parsed(docs))
end

## General HTML rendering - static pages and IJulia –––––––––––––––––––––––––––––––––––––

function save(file::AbstractString, mime::MIME"text/html", doc::Metadata, config::Config)
    config.include_internal ||
            throw(ArgumentError("`config` option `include_internal` must be true for html"))
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writehtml(f, doc, config)
    end

    # copy static files
    src = joinpath(dirname(@__FILE__), "..", "..", "static")
    dst = joinpath(dirname(file), "static")
    isdir(dst) || mkpath(dst)
    for file in readdir(src)
        info("copying $(file) to $(dst)")
        cp(joinpath(src, file), joinpath(dst, file))
    end
end

type EntriesHtml
    entries::Vector{@compat(Tuple{Module, Any, AbstractEntry})}
end
EntriesHtml() = EntriesHtml(@compat(Tuple{Module, Any, AbstractEntry})[])

function push!(ents::EntriesHtml, modulename::Module, obj, ent::AbstractEntry)
    push!(ents.entries, (modulename, obj, ent))
end

function writehtml(io::IO, doc::Metadata, config::Config)
    headerhtml(io, doc)

    rootdir = isfile(root(doc)) ? dirname(root(doc)) : root(doc)
    for file in manual(doc)
        writemime(io, MIME("text/html"), Markdown.parse(readall(joinpath(rootdir, file))))
    end

    index = Dict{Symbol, Any}()
    for (obj, entry) in entries(doc)
        addentry!(index, obj, entry)
    end

    if !isempty(index)
        println(io, "<h1 id='module-reference'>Reference</h1>")

        ents = EntriesHtml()
        wrap(io, "ul", "class='index'") do
            for k in config.category_order
                haskey(index, k) || continue
                wrap(io, "li") do
                    println(io, "<strong>$(k)s:</strong>")
                end
                wrap(io, "li") do
                    wrap(io, "ul") do
                        for (s, obj) in index[k]
                            push!(ents, modulename(doc), obj, entries(doc)[obj])
                            wrap(io, "li") do
                                href = string(k, "_", generate_html_id(s))
                                print(io, "<a href='#$(href)'>", s, "</a>")
                            end
                        end
                    end
                end
            end
        end
        writehtml(io,ents)
    end
    footerhtml(io, doc, config)
end

function writehtml(io::IO, ents::EntriesHtml)
    wrap(io, "div", "class='entries'") do
        for (modname, obj, ent) in ents.entries
            writehtml(io, modname, obj, ent)
        end
    end
end

function writehtml{category}(io::IO, modname, obj, ent::Entry{category})
    wrap(io, "div", "class='entry'") do
        objname = writeobj(obj, ent)
        idname = "$(category)_" * generate_html_id(objname)
        wrap(io, "div", "id='$(idname)' class='entry-name category-$(category)'") do
            print(io, "<div class='category'>[$(category)] &mdash; </div> ")
            println(io, objname)
        end
        wrap(io, "div", "class='entry-body'") do
            writehtml(io, docs(ent))
            wrap(io, "div", "class='entry-meta'") do
                println(io, "<strong>Details:</strong>")
                wrap(io, "table", "class='meta-table'") do
                    for k in sort(collect(keys(ent.data)))
                        wrap(io, "tr") do
                            print(io, "<td><strong>", k, ":</strong></td>")
                            wrap(io, "td") do
                                writehtml(io, Meta{k}(ent.data[k]))
                            end
                        end
                    end
                end
            end
        end
    end
end

function writehtml(io::IO, md::Meta)
    println(io, "<code>", md.content, "</code>")
end

function writemime(io::IO, mime::MIME"text/html", m::Meta{:parameters})
    wrap(io, "table") do
        for (k, v) in m.content
            wrap(io, "tr") do
                wrap(io, "td") do
                    println(io, "<code>", k, "</code>")
                end
                wrap(io, "td") do
                    writemime(io, MIME("text/html"), Markdown.parse(v))
                end
            end
        end
    end
end

function writehtml(io::IO, m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    print(io, "<a href='$(url(m))'>$(path):$(m.content[1])</a>")
end

function headerhtml(io::IO, doc::Metadata)
    println(io, """
    <!doctype html>

    <meta charset="utf-8">

    <title>$(doc.modname)</title>

    <link rel="stylesheet" type="text/css"
          href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.css">

    <link rel="stylesheet" type="text/css" href="static/custom.css">

    <h1 class='package-header'>$(doc.modname)</h1>
    """)
end

function footerhtml(io::IO, doc::Metadata, config::Config)
    println(io, """

    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/mode/julia/julia.min.js"></script>

    $(config.mathjax ? "<script type='text/javascript' src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>" : "")

    <script type="text/javascript" src="static/custom.js"></script>
    """)
end

function wrap(fn::Function, io::IO, tag::AbstractString, attributes::AbstractString = "")
    println(io, "<", tag, " ", attributes, ">")
    fn()
    println(io, "</", tag, ">")
end

## Utils

# Convert's a string to a valid html id
function generate_html_id(s::AbstractString)
    # http://www.w3.org/TR/html4/types.html#type-id
    # ID tokens must begin with a letter ([A-Za-z]) and may be followed by any number of letters,
    # digits ([0-9]), hyphens ("-"), underscores ("_"), colons (":"), and periods (".").
    valid_chars = Set(Char['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
                           'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                           'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
                           'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                           '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                           '-', '_', ':', '.'])

    replace_chars = Set(Char[' ', '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',',
                             '/', ';', '<', '=', '>', '?', '@', '[', ']', '^', '`', '{',
                             '¦', '}', '~'])
    io = IOBuffer()
    for c in s
        if c in valid_chars
            write(io, lowercase(string(c)))
        elseif c in replace_chars
            write(io, "_")
        else
            write(io, string(Int(c)))
        end
    end
    # Note: In our case no need to check for begins with letter or is empty
    #  we prepend always the category
    return takebuf_string(io)
end
