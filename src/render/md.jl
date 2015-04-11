## Docs-specific rendering

function writemd(io::IO, docs::Docs{:md})
    println(io, docs.data)
end

## General markdown rendering
print_help(io::IO, cv::ASCIIString, item) = cv in MDHTAGS            ?
                                            println(io, "$cv $item") :
                                            println(io, cv, item, cv)

function savemd(file::String, doc::Metadata, config::Config)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemd(f, doc, config)
    end
end

type Entries
    entries::Vector{(Module, Any, Entry)}
end
Entries() = Entries((Module, Any, Entry)[])

function push!(ents::Entries, modulename::Module, obj, ent::Entry)
    push!(ents.entries, (modulename, obj, ent))
end

function writemd(io::IO, doc::Metadata, config::Config)
    headermd(io, doc, config)

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
        writemd(io, ents, config)
    end
    footermd(io)
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
        print_help(io, config.mdstyle_exported, "Exported")
        for (modname, obj, ent) in exported.entries
            writemd(io, modname, obj, ent, config)
        end
    end
    if !isempty(internal.entries)
        print_help(io, config.mdstyle_internal, "Internal")
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

function footermd(io::IO)
    println(io, "")
end


#  =============== TODO: if no Problems arise delete this below
#length(ents::Entries) = length(ents.entries)  # TODO: if no Problems arise delete this


#function writemd(io::IO, mime::MIME"text/md", manual::Manual)
#    println(""">>SEEMS IT GETS NOT CALLED: writemd(io::IO, mime::MIME"text/md", manual::Manual) is this done in line 36??""")
#    for page in pages(manual)
#        writemd(io, MIME("text/md"), docs(page))
#    end
#end
#function writemd(io::IO, mime::MIME"text/md", m::Meta{:parameters})
#    for (k, v) in m.content
#        println(io, k)
#    end
#    println("""=====2 """, @which writemd(io, MIME("text/md"), v))
#    writemd(io, MIME("text/md"), v)
#end
