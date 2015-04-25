## Docs-specific rendering

function writemd(io::IO, docs::Docile.Interface.Docs{:md})
    println(io, docs.data)
end

## General markdown rendering
print_help(io::IO, cv::ASCIIString, item) = cv in MDHTAGS            ?
                                            println(io, "$cv $item") :
                                            println(io, cv, item, cv)

function save(file::AbstractString, mime::MIME"text/md", doc::Metadata, config::Config)
    ents = Entries()
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        headermd(f, doc, config)
        ents = writemd(f, doc, ents, config)
    end
    return ents
end

function writemd(io::IO, doc::Metadata, ents::Entries, config::Config)
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
        for k in config.category_order
            haskey(index, k) || continue
            for (s, obj) in index[k]
                push!(ents, modulename(doc), obj, entries(doc)[obj])
            end
        end
        println(io)
        writemd(io, ents, config)
    end
    return ents
end

function writemd(io::IO, ents::Entries, config::Config)
    exported = Entries()
    internal = Entries()

    for (modname, obj, ent) in ents.entries
        isexported(modname, obj) ?
            push!(exported, modname, obj, ent) :
            config.include_internal && push!(internal, modname, obj, ent)
    end

    if !isempty(exported.entries)
        print_help(io, config.mdstyle_subheader, "Exported")
        for (modname, obj, ent) in exported.entries
            writemd(io, modname, obj, ent, config)
        end
    end
    if !isempty(internal.entries)
        print_help(io, config.mdstyle_subheader, "Internal")
        for (modname, obj, ent) in internal.entries
            writemd(io, modname, obj, ent, config)
        end
    end
end

function writemd{category}(io::IO, modname, obj, ent::Entry{category}, config::Config)
    objname = writeobj(obj, ent)
    println(io, "---\n")
    print_help(io, config.mdstyle_objname, objname)
    writemd(io, docs(ent))
    println(io)
    for k in sort(collect(keys(ent.data)))
        print_help(io, config.mdstyle_meta, "$k:")
        writemd(io, Meta{k}(ent.data[k]))
        println(io)
    end
end

function writemd(io::IO, md::Meta)
    println(io, md.content)
end

function writemd(io::IO, m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    println(io, "[$(path):$(m.content[1])]($(url(m)))")
end

function headermd(io::IO, doc::Metadata, config::Config)
    print_help(io, config.mdstyle_header, doc.modname)
end

### API-Index ----------------------------------------------------------------------------

function save(file::AbstractString, mime::MIME"text/md", index_entries::Vector, c::Config)
    throw(ArgumentError("The markdown format does currently not support saving of separate API-Index pages.)"))
end
