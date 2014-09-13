@doc tex"""
Write the documentation stored in `modulename` module to the specified file `file`
in the format guessed from the file's extension.

If MathJax support is required then the optional keyword argument
`mathjax::Bool` may be given. MathJax uses `\(...\)` for in-line maths
and `\[...\]` or `$$...$$` for display equations.

Currently supported formats: `HTML`.
""" ->
function save(file::String, modulename::Module; mathjax = false)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename); mathjax = mathjax)
end

## docstring parser selection –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

const PARSERS = [
    :md => Markdown.parse
    # Additional parsers go here.
    ]

function parsedocs(parser::Symbol, content::String)
    haskey(PARSERS, parser) || error("no parser available for '$(parser)' format.")
    PARSERS[parser](content)
end

function parsedocs(file::String, contents::String)
    parser = symbol(strip(last(splitext(file)), '.'))
    parsedocs(parser, contents)
end

parsedocs(entry::Entry) = parsedocs(get(metadata(entry), :format, :md), docs(entry))

## plain ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/plain", ents::Entries)
    for (modname, obj, ent) in ents.entries
        println(io, ">>>")
        print(io, colorize(:white, "\n [$(category(ent))] "; mode = "bold"))
        print(io, colorize(:white, string(join(fullname(modname), "."), ".")))
        println(io, colorize(:blue, "$(writeobj(obj))\n"; mode = "bold"))
        writemime(io, mime, ent)
    end
end

function writemime(io, mime::MIME"text/plain", entry::Entry)
    # Parse docstring into AST and print it out.
    writemime(io, mime, parsedocs(entry))
    
    # Print metadata if any is available
    isempty(metadata(entry)) || println(io, colorize(:green, " Details:\n"; mode = "bold"))
    for (k, v) in metadata(entry)
        if isa(v, Vector)
            println(io, "\t", k, ":")
            for line in v
                if isa(line, NTuple)
                    println(io, "\t\t", colorize(:cyan, string(line[1])), ": ", line[2])
                else
                    println(io, "\t\t", string(line))
                end
            end
        else
            println(io, "\t", k, ": ", v)
        end
        println(io)
    end
end

function writemime(io::IO, mime::MIME"text/plain", manual::Manual)
    for (file, contents) in pages(manual)
        println(io, colorize(:green, "File: "), file)
        writemime(io, mime, parsedocs(file, contents))
    end
end

## html –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function save(file::String, mime::MIME"text/html", documentation::Documentation; mathjax = false)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, documentation; mathjax = mathjax)
    end
    
    # copy static files
    src = joinpath(Pkg.dir("Lexicon"), "static")
    dst = joinpath(dirname(file), "static")
    isdir(dst) || mkpath(dst)
    for file in readdir(src)
        info("copying $(file) to $(dst)")
        cp(joinpath(src, file), joinpath(dst, file))
    end
end

function writemime(io::IO, mime::MIME"text/html", manual::Manual)
    for (file, contents) in pages(manual)
        writemime(io, mime, Markdown.parse(contents))
    end
end

const CATEGORY_ORDER = [:module, :function, :method, :type, :macro, :global]

function writemime(io::IO, mime::MIME"text/html", documentation::Documentation; mathjax = false)
    header(io, mime, documentation)
    writemime(io, mime, manual(documentation))
    
    index = Dict{Symbol, Any}()
    for (obj, entry) in entries(documentation)
        addentry!(index, obj, entry)
    end
    
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
                        push!(ents, modulename(documentation), obj, entries(documentation)[obj])
                        wrap(io, "li") do
                            print(io, "<a href='#$(s)'>", s, "</a>")
                        end
                    end
                end
            end
        end
    end
    writemime(io, mime, ents)
    footer(io, mime, documentation; mathjax = mathjax)
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
        objname = writeobj(obj)
        wrap(io, "div", "id='$(objname)' class='entry-name category-$(category)'") do
            print(io, "<div class='category'>[$(category)] &mdash; </div> ")
            println(io, objname)
        end
        wrap(io, "div", "class='entry-body'") do
            writemime(io, mime, parsedocs(ent))
            wrap(io, "div", "class='entry-meta'") do
                println(io, "<strong>Details:</strong>")
                wrap(io, "table", "class='meta-table'") do
                    for k in sort(collect(keys(ent.meta)))
                        wrap(io, "tr") do
                            print(io, "<td><strong>", k, ":</strong></td>")
                            wrap(io, "td") do
                                writemime(io, mime, Meta{k}(ent.meta[k]))
                            end
                        end
                    end
                end
            end
        end
    end
end

type Meta{keyword}
    content
end

function writemime(io::IO, mime::MIME"text/html", md::Meta)
    println(io, "<code>", md.content, "</code>")
end

function writemime(io::IO, ::MIME"text/html", m::Meta{:parameters})
    for (k, v) in m.content
        println(io, "<p><code>", k, ":</code>", v, "</p>")
    end
end

function writemime(io::IO, ::MIME"text/html", m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    print(io, "<code><a href='$(url(m))'>$(path):$(m.content[1])</a></code>")
end

function header(io::IO, ::MIME"text/html", doc::Documentation)
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

function footer(io::IO, ::MIME"text/html", doc::Documentation; mathjax = false)
    println(io, """
    
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/mode/julia/julia.min.js"></script>
    
    $(mathjax ? "<script type='text/javascript' src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>" : "")
    
    <script type="text/javascript" src="static/custom.js"></script>
    """)
end

# ## utils ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function wrap(fn::Function, io::IO, tag::String, attributes::String = "")
    println(io, "<", tag, " ", attributes, ">")
    fn()
    println(io, "</", tag, ">")
end

writeobj(any) = string(any)
writeobj(m::Method) = first(split(string(m), " at "))

function addentry!{category}(index, obj, entry::Entry{category})
    section, pair = get!(index, category, (String, Any)[]), (writeobj(obj), obj)
    insert!(section, searchsortedlast(section, pair, by = x -> first(x)) + 1, pair)
end

# from base/methodshow.jl
function url(m::Meta{:source})
    line, file = m.content
    try
        d = dirname(file)
        u = Pkg.Git.readchomp(`config remote.origin.url`, dir=d)
        u = match(Pkg.Git.GITHUB_REGEX,u).captures[1]
        root = cd(d) do # dir=d confuses --show-toplevel, apparently
            Pkg.Git.readchomp(`rev-parse --show-toplevel`)
        end
        if beginswith(file, root)
            commit = Pkg.Git.readchomp(`rev-parse HEAD`, dir=d)
            return "https://github.com/$u/tree/$commit/"*file[length(root)+2:end]*"#L$line"
        else
            return Base.fileurl(file)
        end
    catch
        return Base.fileurl(file)
    end
end
