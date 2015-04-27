## General markdown rendering  –––––––––––––––––––––––––––––––––––––

# noneH_addnewline add a new line if mdstyle is not a H1-6  but italic, bold, or normal
function println_mdstyle(io::IO, mdstyle::ASCIIString, item, noneH_addnewline = true)
    if mdstyle in MDHTAGS
        println(io, "$mdstyle $item")
    else
        println(io, "$mdstyle$item$mdstyle")
        noneH_addnewline && println(io)
    end
end

function save(file::AbstractString, mime::MIME"text/md", doc::Metadata, config::Config)
    ents = Entries(abspath(file), modulename(doc), config)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        headermd(f, doc, config)
        ents = mainsetup(f, mime, doc, ents, config)
    end
    return ents
end

function process_entries(io::IO, mime::MIME"text/md", modulename::Module, grpname::AbstractString,
                                                entries::Dict, grp_anchors::Vector, config::Config)
    if has_items(entries)
        if config.md_subheader == :simple
            println(io)
            grp_anchorname = generate_html_id("$(string(modulename))__$(grpname)")
            println(io, """<a id="$grp_anchorname" class="lexicon_grp_definition"></a>""")
            println_mdstyle(io, config.mdstyle_subheader,
                            string(grpname, config.md_grp_permalink ? " [¶](#$grp_anchorname)" : ""))
            println(io)
            # collect grp_anchorname
            push!(grp_anchors, grpname, grp_anchorname)
        end
        for k in config.category_order
            if length(entries[k]) > 0
                if config.md_subheader == :category
                    println(io)
                    final_grpname = "$(ucfirst(string(k)))s [$grpname]"
                    tmp_id_tag = "$(string(modulename))__$(string(k))s_$grpname"
                    grp_anchorname = generate_html_id(tmp_id_tag)
                    println(io, """<a id="$grp_anchorname" class="lexicon_grp_definition"></a>""")
                    println_mdstyle(io, config.mdstyle_subheader, string(final_grpname,
                                    config.md_grp_permalink ? " [¶](#$grp_anchorname)" : ""))
                    println(io)
                    # collect grp_anchorname
                    push!(grp_anchors, final_grpname, grp_anchorname)
                end
                for (obj, ent, anchorname) in entries[k]
                    writemd(io, obj, ent, anchorname, config)
                end
            end
        end
    end
end

function writemime(io::IO, mime::MIME"text/md", manual::AbstractString)
    println(io, manual)
end

function writemd{category}(io::IO, obj, ent::Entry{category},
                           anchorname::AbstractString, config::Config)
    objname = writeobj(obj, ent)
    println(io, "---\n")
    println(io, """<a id="$anchorname" class="lexicon_definition"></a>""")
    println_mdstyle(io, config.mdstyle_objname,
                    string(objname, config.md_permalink ? " [¶](#$anchorname)" : ""))
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
    println(io)
end

## Docs-specific rendering

function writemd(io::IO, docs::Docile.Interface.Docs{:md})
    println(io, docs.data)
end

### API-Index ----------------------------------------------------------------------------

function save(file::AbstractString, mime::MIME"text/md", index::Index, config::Config)
    # Write the API-Index file.
    indexfiledir = dirname(abspath(file))
    isfile(file) || mkpath(indexfiledir)
    open(file, "w") do f
        info("writing API-Index to $(file)")
        println_mdstyle(f, config.mdstyle_header, "API-INDEX\n")
        println(f)

        for ent in index.entries
            if ent.has_items
                relsourcepath = relpath(ent.sourcepath, indexfiledir)
                println_mdstyle(f, config.mdstyle_index_mod,
                                   "$(config.md_index_modprefix)$(string(ent.modulename))\n")
                if config.md_index_grpsection && !isempty(ent.grp_anchors)
                    println(f, "---\n")
                    println_mdstyle(f, config.mdstyle_subheader, "Sections\n")
                    for (final_grpname, grp_anchorname) in ent.grp_anchors
                        println(f, "[$(final_grpname)]($relsourcepath#$grp_anchorname)\n")
                    end
                end
                process_api_index(f, "Exported", ent.exported, relsourcepath, config)
                process_api_index(f, "Internal", ent.internal, relsourcepath, config)
            end
        end
    end
end

function process_api_index(io::IO, grpname::AbstractString, entries::Dict,
                           relsourcepath::AbstractString, config::Config)
    if has_items(entries)
        config.md_subheader == :simple && (println(io, "---\n");
                                       println_mdstyle(io, config.mdstyle_subheader, "$grpname\n"))
        for k in config.category_order
            if length(entries[k]) > 0
                if config.md_subheader == :category
                    println(io, "---\n")
                    println_mdstyle(io, config.mdstyle_subheader, "$(ucfirst(string(k)))s [$grpname]\n")
                end
                for (obj, ent, anchorname) in entries[k]
                    description = split(data(docs(ent)), '\n')[1]
                    println(io, "[$(writeobj(obj, ent))]($relsourcepath#$anchorname)  $description\n")
                end
            end
        end
    end
end
