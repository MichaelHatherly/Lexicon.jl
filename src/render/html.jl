## Docs-specific rendering ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/html", docs::Docs{:md})
    writemime(io, mime, parsed(docs))
end

## General HTML rendering - static pages and IJulia –––––––––––––––––––––––––––––––––––––

function save(file::String, mime::MIME"text/html", doc::Metadata; mathjax = false)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, doc; mathjax = mathjax)
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

type Entries
    entries::Vector{(Module, Any, Entry)}
end
Entries() = Entries((Module, Any, Entry)[])

function push!(ents::Entries, modulename::Module, obj, ent::Entry)
    push!(ents.entries, (modulename, obj, ent))
end

length(ents::Entries) = length(ents.entries)

function writemime(io::IO, mime::MIME"text/html", manual::Manual)
    for page in pages(manual)
        writemime(io, mime, docs(page))
    end
end

function writemime(io::IO, mime::MIME"text/html", doc::Metadata; mathjax = false)
    header(io, mime, doc)

    rootdir = isfile(root(doc)) ? dirname(root(doc)) : root(doc)
    for file in manual(doc)
        writemime(io, mime, Markdown.parse(readall(joinpath(rootdir, file))))
    end

    index = Dict{Symbol, Any}()
    for (obj, entry) in entries(doc)
        addentry!(index, obj, entry)
    end

    if !isempty(index)
        println(io, "<h1 id='module-reference'>Reference</h1>")

        ents = Entries()
        wrap(io, "ul", "class='index'") do
            for k in CATEGORY_ORDER
                haskey(index, k) || continue
                wrap(io, "li") do
                    println(io, "<strong>$(k)s:</strong>")
                end
                wrap(io, "li") do
                    wrap(io, "ul") do
                        for (s, obj) in index[k]
                            push!(ents, modulename(doc), obj, entries(doc)[obj])
                            wrap(io, "li") do
                                print(io, "<a href='#$(s)'>", s, "</a>")
                            end
                        end
                    end
                end
            end
        end
        writemime(io, mime, ents)
    end
    footer(io, mime, doc; mathjax = mathjax)
end

function writemime(io::IO, mime::MIME"text/html", ents::Entries)
    wrap(io, "div", "class='entries'") do
        for (modname, obj, ent) in ents.entries
            writemime(io, mime, modname, obj, ent)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/html", modname, obj, ent::Entry{category})
    wrap(io, "div", "class='entry'") do
        objname = writeobj(obj, ent)
        wrap(io, "div", "id='$(objname)' class='entry-name category-$(category)'") do
            print(io, "<div class='category'>[$(category)] &mdash; </div> ")
            println(io, objname)
        end
        wrap(io, "div", "class='entry-body'") do
            writemime(io, mime, docs(ent))
            wrap(io, "div", "class='entry-meta'") do
                println(io, "<strong>Details:</strong>")
                wrap(io, "table", "class='meta-table'") do
                    for k in sort(collect(keys(ent.data)))
                        wrap(io, "tr") do
                            print(io, "<td><strong>", k, ":</strong></td>")
                            wrap(io, "td") do
                                writemime(io, mime, Meta{k}(ent.data[k]))
                            end
                        end
                    end
                end
            end
        end
    end
end

function writemime(io::IO, mime::MIME"text/html", md::Meta)
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
                    writemime(io, mime, Markdown.parse(v))
                end
            end
        end
    end
end

function writemime(io::IO, ::MIME"text/html", m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    print(io, "<a href='$(url(m))'>$(path):$(m.content[1])</a>")
end

function header(io::IO, ::MIME"text/html", doc::Metadata)
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

function footer(io::IO, ::MIME"text/html", doc::Metadata; mathjax = false)
    println(io, """

    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/mode/julia/julia.min.js"></script>

    $(mathjax ? "<script type='text/javascript' src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>" : "")

    <script type="text/javascript" src="static/custom.js"></script>
    """)
end

function wrap(fn::Function, io::IO, tag::String, attributes::String = "")
    println(io, "<", tag, " ", attributes, ">")
    fn()
    println(io, "</", tag, ">")
end
