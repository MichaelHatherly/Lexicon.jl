## Docs-specific rendering

function writemime(io::IO, mime::MIME"text/md", docs::Docs{:md},
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
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

"Permalink Entry used when collection needed info."
type PLEntry
    objname::ByteString
    idname::ByteString
    descr::ByteString
    relsourcepath::ByteString
end

"Permalink Main helper type."
type PLMain
    genidxfile::ByteString
    mdoutfile::ByteString      # reference to the current proccessed output file needed for relative links.
    idxrelpath::ByteString     # current relative path: mdoutfile to genidxfile
    headerstyle::ByteString
    modnamestyle::ByteString
    data::Dict{ByteString, Dict{Symbol, Array{PLEntry,1}}}
end

"""
Return a relative filepath.

Relative from `startpath` to `path`.
This is a path computation:
the filesystem is not accessed to confirm the existence or nature of `path` or `startpath`.

**Example**

```julia
relpath_ = relpath("/home/user/Downloads", pwd())

```
"""
function relpath(path::ByteString, startpath::ByteString)
    pardir = ".."
    if isabspath(path) && !contains(path, "/.")
        path_arr = split(path, Base.path_separator_re)
    else
        path_arr = split(abspath(path), Base.path_separator_re)
    end
    if isabspath(startpath) && !contains(path, "/.")
        start_arr = split(startpath, Base.path_separator_re)
    else
        start_arr = split(abspath(startpath), Base.path_separator_re)
    end

    count = 0
    while count < min(length(path_arr), length(start_arr))
        count += 1
        if path_arr[count] != start_arr[count]
            count -= 1
            break
        end
    end
    rel_path = "..$(Base.path_separator)"^(length(start_arr)-count) * join(path_arr[count+1:end],
                                                                             Base.path_separator)
    return rel_path
end

"""
Starts collecting data for API-Index.

This must be called before any Modules are saved. Even in the case one does not want to save
a API-Index page.

**Arguments:**

* `genidxfile`: The file any API-Index page will be written to.
* `headerstyle`: Style for the API-Index header
* `modnamestyle`: Style for the module names.

**Returns:**

* PLMain(): which is needed as input to the save methods.

Seealso: `savegenidx`

"""
function startgenidx(genidxfile::ByteString; headerstyle::ByteString = "#", modnamestyle::ByteString = "####")
    vaild_tags = vcat(HTAGS, STYLETAGS)
    vaild_tags_str = "[$(join(vaild_tags, ", "))]"
    headerstyle in vaild_tags || error("Invalid headerstyle:  `$headerstyle`. Valid values: $vaild_tags_str.")
    modnamestyle in vaild_tags || error("Invalid modnamestyle:  `$modnamestyle`. Valid values: $vaild_tags_str.")
    return PLMain(abspath(genidxfile), "", "", headerstyle, modnamestyle, Dict())
end

"""
Saves the generated API-Index to file.

This must be called before any Modules are saved. Even in the case one does not want to save
a API-Index page.

**Arguments:**

* `plmain`: PLMain()

Seealso: `startgenidx`

"""
function savegenidx(plmain::PLMain)
    file = plmain.genidxfile
    sortedmodnames = sort(collect(keys(plmain.data)))
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do io
        info("writing API-Index to $(file)")
        print_help(io, plmain.headerstyle, "API-Index")
        print_help(io, plmain.modnamestyle, "Module-Index")
        writemoduleidx(io, plmain, sortedmodnames)

        # modules items: sorted alphabetically
        for modname in sortedmodnames
            writeidxmod(io, plmain, modname)
        end
    end
end

function writemoduleidx(io::IO, plmain::PLMain, sortedmodnames::Array{ByteString,1})
    for modname in sortedmodnames
        println(io, "[$modname](#$modname.1)\n")
    end
end

function writeidxmod(io::IO, plmain::PLMain, modname::ByteString)
    # module header
    println(io, "\n---")
    println(io, "<a id=$modname.1></a>")
    print_help(io, plmain.modnamestyle, "Module: $modname")
    println(io, "\n")

    for basename in sort(collect(keys(plmain.data[modname])))
        for plentry in plmain.data[modname][basename]
            println(io, "[$(plentry.objname)]($(plentry.relsourcepath)#$(plentry.idname))   $(plentry.descr)\n")
        end
    end
end

"""
Prepares a PLEntry - pushes it to the correct `plmain` Vector.
It adds any necessary dictionary keys.

**Returns:**

* PLEntry: Returns also the just prepared/added PLEntry.
"""
function push!(plmain::PLMain, modname::Module, obj, ent::Entry)
    isa(ent, Docile.Entry{:macro}) ? basename = Docile.Interface.macroname(ent) : basename = Docile.Interface.name(obj)
    modname = string(modname)
    relsourcepath = relpath(plmain.mdoutfile, dirname(plmain.genidxfile))
    plentry = PLEntry(writeobj(obj, ent), "", split(docs(ent).data, '\n')[1], relsourcepath)

    if modname in keys(plmain.data)
        if basename in keys(plmain.data[modname])
            idnum = length(plmain.data[modname][basename]) + 1
            plentry.idname = "$basename.$idnum"
            temp_arr = plmain.data[modname][basename]
            Base.push!(temp_arr, plentry)
        else
            plentry.idname = "$basename.1"
            plmain.data[modname][basename] = [plentry]
        end
    else
        plentry.idname = "$basename.1"
        plmain.data[modname] = Dict([(basename, [plentry])])
    end
    return plentry
end

function save(file::String, mime::MIME"text/md", doc::Metadata, plmain::PLMain,
                mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE;
                mathjax = false, include_internal = true, permalink::Bool = true)
    validate(mdstyle)
    # update plmain with the: mdoutfile needed to calculate the relative Api-Index links.
    plmain.mdoutfile = abspath(file)
    # Write the main file.
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, doc, plmain, mdstyle;  mathjax = mathjax,
                    include_internal = include_internal, permalink = permalink)
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

function writemime(io::IO, mime::MIME"text/md", manual::Manual,
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    for page in pages(manual)
        writemime(io, mime, docs(page), mdstyle)
    end
end

function writemime(io::IO, mime::MIME"text/md", doc::Metadata, plmain::PLMain,
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE; mathjax = false,
                    include_internal = true, permalink::Bool = true)
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
        writemime(io, mime, ents, plmain, mdstyle;
                    include_internal = include_internal, permalink = permalink)
    end
    footer(io, mime, doc; mathjax = mathjax)
end

function writemime(io::IO, mime::MIME"text/md", ents::Entries, plmain::PLMain,
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE;
                    include_internal = true, permalink::Bool = true)
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
            writemime(io, mime, modname, obj, ent, plmain, mdstyle; permalink = permalink)
        end
    end
    if !isempty(internal.entries)
        print_help(io, mdstyle[:internal], "Internal")
        for (modname, obj, ent) in internal.entries
            writemime(io, mime, modname, obj, ent, plmain, mdstyle; permalink = permalink)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/md", modname, obj, ent::Entry{category},
                                plmain::PLMain, mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE;
                                permalink::Bool = true)
    last_plentry = push!(plmain, modname, obj, ent)
    objname = last_plentry.objname
    println(io, "---\n")
    
    println(io, """<a id="$(last_plentry.idname)" class="headerfix"></a>""")
    if permalink
        print_help(io, mdstyle[:objname], "$objname   [¶](#$(last_plentry.idname))")
    else
        print_help(io, mdstyle[:objname], objname)
    end
    writemime(io, mime, docs(ent), mdstyle)
    println(io)
    for k in sort(collect(keys(ent.data)))
        print_help(io, mdstyle[:meta], "$k:")
        writemime(io, mime, Meta{k}(ent.data[k]), mdstyle)
        println(io)
    end
end

function writemime(io::IO, mime::MIME"text/md", md::Meta,
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    println(io, md.content)
end

function writemime(io::IO, mime::MIME"text/md", m::Meta{:parameters},
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    for (k, v) in m.content
        println(io, k)
    end
    writemime(io, mime, v, mdstyle)
end

function writemime(io::IO, ::MIME"text/md", m::Meta{:source},
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    println(io, "[$(path):$(m.content[1])]($(url(m)))")
end

function header(io::IO, ::MIME"text/md", doc::Metadata,
                    mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE)
    print_help(io, mdstyle[:header], doc.modname)
end

function footer(io::IO, ::MIME"text/md", doc::Metadata,
                mdstyle::Dict{Symbol, ByteString} = DEFAULT_MDSTYLE; mathjax = false)
    println(io, "")
end
