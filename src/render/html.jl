## General HTML rendering - static pages and IJulia –––––––––––––––––––––––––––––––––––––

function save(file::AbstractString, mime::MIME"text/html", doc::Metadata, config::Config)
    config.include_internal ||
            throw(ArgumentError("`config` option `include_internal` must be true for html"))
    ents = EntriesHtml()
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        headerhtml(f, doc, config)
        ents = writehtml(f, doc, ents, config)
        footerhtml(f, doc, config)
    end

    # copy static files
    src = joinpath(dirname(@__FILE__), "..", "..", "static")
    dst = joinpath(dirname(file), "static")
    isdir(dst) || mkpath(dst)
    for file in readdir(src)
        info("copying $(file) to $(dst)")
        cp(joinpath(src, file), joinpath(dst, file); remove_destination=true)
    end
    return ents
end

type EntriesHtml
    entries::Vector{@compat(Tuple{Module, Any, AbstractEntry})}
end
EntriesHtml() = EntriesHtml(@compat(Tuple{Module, Any, AbstractEntry})[])

function push!(ents::EntriesHtml, modulename::Module, obj, ent::AbstractEntry)
    push!(ents.entries, (modulename, obj, ent))
end

function writehtml(io::IO, doc::Metadata, ents::EntriesHtml, config::Config)
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
        writehtml(io,ents, config)
    end
    return ents
end

function writehtml(io::IO, ents::EntriesHtml, config::Config)
    wrap(io, "div", "class='entries'") do
        for (modname, obj, ent) in ents.entries
            writehtml(io, modname, obj, ent, config)
        end
    end
end

function writehtml{category}(io::IO, modname, obj, ent::Entry{category}, config::Config)
    wrap(io, "div", "class='entry'") do
        objname = writeobj(obj, ent)
        idname = "$(category)_" * generate_html_id(objname)
        wrap(io, "div", "id='$(idname)' class='entry-name category-$(category)'") do
            print(io, "<div class='category'>[$(category)] &mdash; </div> ")
            println(io, objname)
        end
        wrap(io, "div", "class='entry-body'") do
            writehtml(io, docs(ent))
            if has_output_metadata(ent, config)
                wrap(io, "div", "class='entry-meta'") do
                    println(io, "<strong>Details:</strong>")
                    wrap(io, "table", "class='meta-table'") do
                        for m in config.metadata_order
                            if haskey(ent.data, m)
                                wrap(io, "tr") do
                                    print(io, "<td><strong>", m, ":</strong></td>")
                                    wrap(io, "td") do
                                        writehtml(io, Meta{m}(ent.data[m]))
                                    end
                                end
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

function headerhtml(io::IO, doc::Metadata, config::Config)
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

## Docs-specific rendering ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writehtml(io::IO, docs::Docile.Interface.Docs{:md})
    writemime(io, MIME("text/html"), parsed(docs))
end

### API-Index ----------------------------------------------------------------------------

function save(file::AbstractString, mime::MIME"text/html", index::Index, c::Config)
    throw(ArgumentError("The html format does currently not support saving of separate API-Index pages.)"))
end
