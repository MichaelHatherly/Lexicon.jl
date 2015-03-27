## Docs-specific rendering ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/md", docs::Docs{:md})
    println(io, docs.data)
end

## General markdown rendering ------------------------–––––––––––––––––––––––––––––––––––

function save(file::String, mime::MIME"text/md", doc::Metadata; mathjax = false, include_internal = true)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, doc; mathjax = mathjax, include_internal = include_internal)
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

function writemime(io::IO, mime::MIME"text/md", manual::Manual)
    for page in pages(manual)
        writemime(io, mime, docs(page))
    end
end

function writemime(io::IO, mime::MIME"text/md", doc::Metadata; mathjax = false, include_internal = true)
    header(io, mime, doc)

    # Root may be a file or directory. Get the dir.
    rootdir = isfile(root(doc)) ? dirname(root(doc)) : root(doc)

    for file in manual(doc)
        println(io, readall(joinpath(rootdir, file)))
    end

    index = Dict{Symbol, Any}()
    for (obj, entry) in entries(doc)
        addentry!(index, obj, entry)
    end

    if !isempty(index)
        ents = Entries()
        for k in CATEGORY_ORDER
            haskey(index, k) || continue
            ## println(io, "## **$(k)s:**")
            for (s, obj) in index[k]
                push!(ents, modulename(doc), obj, entries(doc)[obj])
                ## println(io, "* [$(s)](#$(s))")
            end
        end
        println(io)
        writemime(io, mime, ents, include_internal = include_internal)
    end
    footer(io, mime, doc; mathjax = mathjax)
end

function writemime(io::IO, mime::MIME"text/md", ents::Entries; include_internal = true)
    exported = Entries()
    internal = Entries()

    for (modname, obj, ent) in ents.entries
        isexported(modname, obj) ?
            push!(exported, modname, obj, ent) :
            include_internal && push!(internal, modname, obj, ent)
    end

    if !isempty(exported.entries)
        println(io, "## Exported")
        for (modname, obj, ent) in exported.entries
            writemime(io, mime, modname, obj, ent)
        end
    end
    if !isempty(internal.entries)
        println(io, "## Internal")
        for (modname, obj, ent) in internal.entries
            writemime(io, mime, modname, obj, ent)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/md", modname, obj, ent::Entry{category})
    objname = writeobj(obj, ent)
    ## print(io, "<div class='category'>[$(category)] &mdash; </div> ")
    println(io, "---\n\n#### $(objname)")
    writemime(io, mime, docs(ent))
    ## println(io, "**Details:**")
    println(io)
    for k in sort(collect(keys(ent.data)))
        println(io, "**", k, ":**")
        writemime(io, mime, Meta{k}(ent.data[k]))
        println(io)
    end
end

function writemime(io::IO, mime::MIME"text/md", md::Meta)
    println(io, md.content)
end

function writemime(io::IO, mime::MIME"text/md", m::Meta{:parameters})
    for (k, v) in m.content
        println(io, k)
    end
    writemime(io, mime, v)
end

function writemime(io::IO, ::MIME"text/md", m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    println(io, "[$(path):$(m.content[1])]($(url(m)))")
end

function header(io::IO, ::MIME"text/md", doc::Metadata)
    println(io, "# $(doc.modname)")
end

function footer(io::IO, ::MIME"text/md", doc::Metadata; mathjax = false)
    println(io, "")
end
