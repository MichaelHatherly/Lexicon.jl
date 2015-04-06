## Docs-specific rendering

function writemime(io::IO, mime::MIME"text/md", docs::Docs{:md}, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    println(io, docs.data)
end

## General markdown rendering

const DEFAULT_MDSTYLE = Dict{Symbol, ByteString}([
  (:header         , "#"),
  (:objname        , "####"),
  (:meta           , "**"),
  (:exported       , "##"),
  (:internal       , "##"),
])

const HTAGS = ["#", "##", "###", "####", "#####", "######"]
const STYLETAGS = ["", "*", "**"]

print_help(io::IO, cv::ASCIIString, item) = cv in HTAGS ? println(io, "$cv $item") : println(io, cv, item, cv)

function validate(mdstyle::Dict{Symbol, ByteString})
    reg_keys = keys(DEFAULT_MDSTYLE)
    length(keys(mdstyle)) != length(reg_keys) && error(
            "`mdstyle` expected number of keys: $(length(reg_keys))  Got: $(length(keys(mdstyle)))")
    vaild_tags = vcat(HTAGS,STYLETAGS)
    for (k, v) in mdstyle
        k in reg_keys || error("Invalid mdstyle key:  `$k`. Valid keys: [$(join(reg_keys, ", "))].")
        v in vaild_tags || error("Invalid mdstyle value:  `$v`. Valid values: [$(join(vaild_tags, ", "))].")
    end
end

function save(file::String, mime::MIME"text/md", doc::Metadata, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE;
                                                                                mathjax = false, include_internal = true)
    validate(mdstyle)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, doc, mdstyle; mathjax = mathjax, include_internal = include_internal)
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

function writemime(io::IO, mime::MIME"text/md", manual::Manual, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    for page in pages(manual)
        writemime(io, mime, docs(page), mdstyle)
    end
end

function writemime(io::IO, mime::MIME"text/md", doc::Metadata, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE;
                                                                                mathjax = false, include_internal = true)
    header(io, mime, doc, mdstyle)

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
        writemime(io, mime, ents, mdstyle; include_internal = include_internal)
    end
    footer(io, mime, doc; mathjax = mathjax)
end

function writemime(io::IO, mime::MIME"text/md", ents::Entries,
            mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE; include_internal = true)
    exported = Entries()
    internal = Entries()

    for (modname, obj, ent) in ents.entries
        isexported(modname, obj) ?
            push!(exported, modname, obj, ent) :
            include_internal && push!(internal, modname, obj, ent)
    end

    if !isempty(exported.entries)
        print_help(io, mdstyle[:exported], "Exported")
        for (modname, obj, ent) in exported.entries
            writemime(io, mime, modname, obj, ent, mdstyle)
        end
    end
    if !isempty(internal.entries)
        print_help(io, mdstyle[:internal], "Internal")
        for (modname, obj, ent) in internal.entries
            writemime(io, mime, modname, obj, ent, mdstyle)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/md", modname, obj, ent::Entry{category},
                                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    objname = writeobj(obj, ent)
    println(io, "---\n")
    print_help(io, mdstyle[:objname], objname)
    writemime(io, mime, docs(ent), mdstyle)
    println(io)
    for k in sort(collect(keys(ent.data)))
        print_help(io, mdstyle[:meta], "$k:")
        writemime(io, mime, Meta{k}(ent.data[k]), mdstyle)
        println(io)
    end
end


function writemime(io::IO, mime::MIME"text/md", md::Meta, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    println(io, md.content)
end

function writemime(io::IO, mime::MIME"text/md", m::Meta{:parameters}, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    for (k, v) in m.content
        println(io, k)
    end
    writemime(io, mime, v, mdstyle)
end

function writemime(io::IO, ::MIME"text/md", m::Meta{:source}, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    println(io, "[$(path):$(m.content[1])]($(url(m)))")
end

function header(io::IO, ::MIME"text/md", doc::Metadata, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    print_help(io, mdstyle[:header], doc.modname)
end

function footer(io::IO, ::MIME"text/md", doc::Metadata, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE; mathjax = false)
    println(io, "")
end
