## Docs-specific rendering

function writemime(io::IO, mime::MIME"text/md", docs::Docs{:md})
    println(io, docs.data)
end

## General markdown rendering

const HTAGS = ["#", "##", "###", "####", "#####", "######"]
const STYLETAGS = ["", "*", "**"]

print_help(io::IO, cv::ASCIIString, item) = cv in HTAGS              ?
                                            println(io, "$cv $item") :
                                            println(io, cv, item, cv)

function save(file::String, mime::MIME"text/md", doc::Metadata, config::Config)
    # validate mdstyle
    for k in [:mdstyle_header, :mdstyle_objname, :mdstyle_meta, :mdstyle_exported, :mdstyle_internal]
       getfield(config, k) in vcat(HTAGS,STYLETAGS) ||
                            error("""Invalid mdstyle value: config-item `$k -> $(config[k])`.
                                    Valid values: [$(join(vcat(HTAGS,STYLETAGS), ", "))].""")
    end
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, doc, config)
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

function writemime(io::IO, mime::MIME"text/md", doc::Metadata, config::Config)
    header(io, mime, doc, config)

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
            for (s, obj) in index[k]
                push!(ents, modulename(doc), obj, entries(doc)[obj])
            end
        end
        println(io)
        writemime(io, mime, ents, config)
    end
    footer(io, mime)
end

function writemime(io::IO, mime::MIME"text/md", ents::Entries, config::Config)
    exported = Entries()
    internal = Entries()

    for (modname, obj, ent) in ents.entries
        isexported(modname, obj) ?
            push!(exported, modname, obj, ent) :
            config.include_internal && push!(internal, modname, obj, ent)
    end

    if !isempty(exported.entries)
        print_help(io, config.mdstyle_exported, "Exported")
        for (modname, obj, ent) in exported.entries
            writemime(io, mime, modname, obj, ent, config)
        end
    end
    if !isempty(internal.entries)
        print_help(io, config.mdstyle_internal, "Internal")
        for (modname, obj, ent) in internal.entries
            writemime(io, mime, modname, obj, ent, config)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/md", modname, obj, ent::Entry{category},
                                                                              config::Config)
    objname = writeobj(obj, ent)
    println(io, "---\n")
    print_help(io, config.mdstyle_objname, objname)
    writemime(io, mime, docs(ent))
    println(io)
    for k in sort(collect(keys(ent.data)))
        print_help(io, config.mdstyle_meta, "$k:")
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

function header(io::IO, ::MIME"text/md", doc::Metadata, config::Config)
    print_help(io, config.mdstyle_header, doc.modname)
end

function footer(io::IO, ::MIME"text/md")
    println(io, "")
end
