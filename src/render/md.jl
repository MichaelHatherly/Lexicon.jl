type EntriesMD
    include_internal::Bool
    exported::Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}}
    internal::Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}}

    EntriesMD(config::Config) = new(config.include_internal,
            Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}}
                        ([(c, []) for c in config.category_order]),
            Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}}
                        ([(c, []) for c in config.category_order])
            )
end

function has_items(entries::Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}})
    return sum([length(x) for x in values(entries)]) > 0
end

function push!(ents::EntriesMD, modulename::Module, obj, ent::Entry, anchorname::ByteString,
                                                                                cat::Symbol)
    isexported(modulename, obj)                                           ?
            push!(ents.exported[cat], (modulename, obj, ent, anchorname)) :
            ents.include_internal && push!(ents.internal[cat], (modulename, obj, ent, anchorname))
end

# noneH_addnewline add a new line if mdstyle is not a H1-6  but italic, bold, or normal
function println_mdstyle(io::IO, mdstyle::ASCIIString, item, noneH_addnewline = true)
    mdstyle in MDHTAGS                    ?
            println(io, "$mdstyle $item") :
            (println(io, "$mdstyle$item$mdstyle"); noneH_addnewline && println(io))
end

## Main --------------------------------------------------------------------------------

## General markdown rendering
function save(file::String, mime::MIME"text/md", doc::Metadata, config::Config)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        mainmd(f, doc, file, config)
    end
end

function mainmd(io::IO, doc::Metadata, filepath::String, config::Config)
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
        ents = prepare_entriesmd(index, doc, config)
        if (has_items(ents.exported) || has_items(ents.internal))
            config.md_genindex && (push!(API_INDEX.sourcepaths, abspath(filepath));
                                   push!(API_INDEX.modulenames, string(modulename(doc)));
                                   push!(API_INDEX.entriesmd, ents))
            println(io)
            process_entriesmd(io, "Exported", ents.exported, config)
            process_entriesmd(io, "Internal", ents.internal, config)
        end
    end
end

function prepare_entriesmd(index::Dict{Symbol, Any}, doc::Metadata, config::Config)
    ents = EntriesMD(config)
    if (config.md_genindex || config.md_permalink)
        pageanchors = Dict{Symbol, Dict{String, Int}}([])
        for k in config.category_order
            haskey(index, k) || continue
            k in pageanchors || (pageanchors[k] = Dict([]))
            basenames = pageanchors[k]
            for (s, obj) in index[k]
                ent = entries(doc)[obj]
                if k == :comment
                    basename = "comment"
                else
                    basename = k == :macro                                          ?
                            Base.lowercase(string(Docile.Interface.macroname(ent))) :
                            Base.lowercase(string(Docile.Interface.name(obj)))
                end
                basename in keys(basenames)                  ?
                        anchornum = basenames[basename] += 1 :
                        anchornum = basenames[basename] = 1
                push!(ents, modulename(doc), obj, entries(doc)[obj],
                        "$(string(k))__$(basename).$(anchornum)", k)
            end
        end
    else
        for k in config.category_order
            haskey(index, k) || continue
            for (s, obj) in index[k]
                push!(ents, modulename(doc), obj, entries(doc)[obj], "", k)
            end
        end
    end
    return ents
end

function process_entriesmd(io::IO, grpname::ByteString,
                           entries::Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}},
                           config::Config)
    if has_items(entries)
        config.md_subheader == :SIMPLE && println_mdstyle(io, config.mdstyle_subheader, grpname)
        for k in config.category_order
            if length(entries[k]) > 0
                config.md_subheader == :CATEGORY && println_mdstyle(io, config.mdstyle_subheader,
                                                              "$(ucfirst(string(k)))s [$grpname]\n")
                for (modname, obj, ent, anchorname) in entries[k]
                    writemd(io, modname, obj, ent, anchorname, config)
                end
            end
        end
    end
end

function writemd{category}(io::IO, modname, obj, ent::Entry{category}, anchorname::String,
                                                                            config::Config)
    objname = writeobj(obj, ent)
    println(io, "---\n")
    (config.md_genindex || config.md_permalink) &&
            println(io, """<a id="$anchorname" class="lexicon_definition"></a>""")

    config.md_permalink                                                                 ?
            println_mdstyle(io, config.mdstyle_objname, "$objname   [¶](#$anchorname)") :
            println_mdstyle(io, config.mdstyle_objname, objname)
    writemd(io, docs(ent))
    println(io)
    for k in sort(collect(keys(ent.data)))
        println_mdstyle(io, config.mdstyle_meta, "$k:", false)
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
    println_mdstyle(io, config.mdstyle_header, doc.modname)
end

## Docs-specific rendering
function writemd(io::IO, docs::Docs{:md})
    println(io, docs.data)
end

### API-Index ----------------------------------------------------------------------------

type ApiIndex
    sourcepaths :: Vector{String}
    modulenames :: Vector{String}
    entriesmd   :: Vector{EntriesMD}

    ApiIndex() = new(Vector{String}([]), Vector{String}([]), Vector{EntriesMD}([]))
end

const API_INDEX = ApiIndex()

function savegenindex(file::String, mime::MIME"text/md", c::Config)
    # Write the API-Index file.
    genindexfiledir = dirname(abspath(file))
    isfile(file) || mkpath(genindexfiledir)
    open(file, "w") do f
        info("writing API-Index to $(file)")
        println_mdstyle(f, c.mdstyle_header, "API-INDEX\n")
        println(f)

        for i in 1:length(API_INDEX.sourcepaths)
            relsourcepath = relpath(API_INDEX.sourcepaths[i], genindexfiledir)
            println_mdstyle(f, c.mdstyle_genindex_mod,
                "$(c.md_genindex_modprefix)$(API_INDEX.modulenames[i])\n")

            process_api_index(f, "Exported", API_INDEX.entriesmd[i].exported, relsourcepath, c);
            process_api_index(f, "Internal", API_INDEX.entriesmd[i].internal, relsourcepath, c)
        end
    end
    clear_api_index(API_INDEX)
end

function clear_api_index(api_index::ApiIndex)
    api_index.sourcepaths = Vector{String}([])
    api_index.modulenames = Vector{String}([])
    api_index.entriesmd = Vector{EntriesMD}([])
end

function process_api_index(io::IO, grpname::ByteString,
                           entries::Dict{Symbol, Vector{(Module, Any, Entry, ByteString)}},
                           relsourcepath::String, config::Config)
    if has_items(entries)
        config.md_subheader == :SIMPLE && (println(io, "---\n");
                                       println_mdstyle(io, config.mdstyle_subheader, "$grpname\n"))
        for k in config.category_order
            if length(entries[k]) > 0
                config.md_subheader == :CATEGORY && (println(io, "---\n");
                                                     println_mdstyle(io, config.mdstyle_subheader,
                                                              "$(ucfirst(string(k)))s [$grpname]\n"))
                for (modname, obj, ent, anchorname) in entries[k]
                    description = split(data(docs(ent)), '\n')[1]
                    println(io, "[$(writeobj(obj, ent))]($relsourcepath#$anchorname)  $description\n")
                end
            end
        end
    end
end
