## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docile.Interface.Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------
const MDHTAGS = ["#", "##", "###", "####", "#####", "######"]
const MDSTYLETAGS = ["", "*", "**"]
const MD_SUBHEADER_OPTIONS = [:skip, :simple, :category, :split_category]

file"docs/config.md"
type Config
    category_order              :: Vector{Symbol}
    include_internal            :: Bool
    mathjax                     :: Bool
    mdstyle_header              :: ASCIIString
    mdstyle_objname             :: ASCIIString
    mdstyle_meta                :: ASCIIString
    mdstyle_subheader           :: ASCIIString
    mdstyle_index_mod           :: ASCIIString
    md_permalink                :: Bool
    md_grp_permalink            :: Bool
    md_permalink_char           :: Char
    md_subheader                :: Symbol
    md_split_category_prefixed  :: Bool
    md_index_modprefix          :: ByteString
    md_index_grpsection         :: Bool

    const defaults = Dict{Symbol, Any}([
        (:category_order                , [:module, :function, :method, :type,
                                           :typealias, :macro, :global, :comment]),
        (:include_internal              , true),
        (:mathjax                       , false),
        (:mdstyle_header                , "#"),
        (:mdstyle_objname               , "####"),
        (:mdstyle_meta                  , "*"),
        (:mdstyle_subheader             , "##"),
        (:mdstyle_index_mod             , "##"),
        (:md_permalink                  , true),
        (:md_grp_permalink              , true),
        (:md_permalink_char             , '¶'),
        (:md_subheader                  , :simple),
        (:md_split_category_prefixed    , false),
        (:md_index_modprefix            , "MODULE: "),
        (:md_index_grpsection           , true),
        ])

    """
    Returns a default Config. If any args... are given these will overwrite the defaults.

    ```
    using Lexicon
    config = Config(md_permalink = false, mathjax = true)

    ```
    """
    function Config(; args...)
        return update_config!(new(), merge(defaults, Dict(args)))
    end
end

function update_config!(config::Config, args::Dict)
    for (k, v) in args
        try
            k in fieldnames(Config) ? setfield!(config, k, v) : warn("Invalid setting: '$(k) = $(v)'.")
        catch err # e.g. TypeError
            warn("Invalid setting: '$(k) = $(v)'. Error: $err")
        end
    end

    for k in [:mdstyle_header, :mdstyle_objname, :mdstyle_meta, :mdstyle_subheader, :mdstyle_index_mod]
        getfield(config, k) in vcat(MDHTAGS, MDSTYLETAGS) ||
                error("""Invalid mdstyle : config-item `$k -> $(getfield(config, k))`.
                      Valid values: [$(join(vcat(MDHTAGS, MDSTYLETAGS), ", "))].""")

        config.md_subheader in MD_SUBHEADER_OPTIONS ||
                    error("""Invalid md_subheader : config-item `$k -> $(getfield(config, k))`.
                          Valid values: $MD_SUBHEADER_OPTIONS.""")
    end
    return config
end

# Per Module one 'Entries' is created which has all needed data
type Entries
    sourcepath       :: ByteString
    # savedconfig keeps the config which was used for ` documentation save`
    # name on purpose slightly different to avoid easily mixing it up with a passed argument in index
    # passing all around. e.g. If save uses `md_subheader-:skip` we can not add a Section in API-Index
    savedconfig      :: Config
    index_relpath    :: ByteString
    modulename       :: Module
    has_items        :: Bool            # avoids double checking
    isjoined         :: Bool            # join all for config.md_subheader: skip and category
    exported         :: Dict{Symbol, Vector{@compat(Tuple{Any, AbstractEntry, AbstractString})}}
    internal         :: Dict{Symbol, Vector{@compat(Tuple{Any, AbstractEntry, AbstractString})}}
    joined           :: Dict{Symbol, Vector{@compat(Tuple{Any, AbstractEntry, AbstractString})}}
    grp_anchors      :: Vector{@compat(Tuple{AbstractString, AbstractString})}

    Entries(sourcepath::ByteString, modulename::Module, config::Config) =
                            new(sourcepath, config, "", modulename, false,
                                (config.md_subheader == :skip || config.md_subheader == :category),
                                Dict([(c, []) for c in config.category_order]),
                                Dict([(c, []) for c in config.category_order]),
                                Dict([(c, []) for c in config.category_order]),
                                [])
end

function has_items(entries::Dict)
    return sum([length(x) for x in values(entries)]) > 0
end

function push!(ents::Entries, obj, ent::AbstractEntry, anchorname::AbstractString, cat::Symbol)
    if ents.isjoined
        push!(ents.joined[cat], (obj, ent, anchorname))
    else
        if isexported(ents.modulename, obj)
            push!(ents.exported[cat], (obj, ent, anchorname))
        else ents.savedconfig.include_internal
            push!(ents.internal[cat], (obj, ent, anchorname))
        end
    end
end

function push!(grp_anchors::Vector, grpname::AbstractString, grp_anchorname::AbstractString)
    push!(grp_anchors, (grpname, grp_anchorname))
end

type Index
    entries::Vector{Entries}
end
Index() = Index(Vector{Entries}[])

function update!(index::Index, ents::Entries)
    push!(index.entries, ents)
end

function mainsetup(io::IO, mime::MIME, doc::Metadata, ents::Entries)
    # Root may be a file or directory. Get the dir.
    rootdir = isfile(root(doc)) ? dirname(root(doc)) : root(doc)
    for file in manual(doc)
        writemime(io, mime, readall(joinpath(rootdir, file)))
    end
    idx = Dict{Symbol, Any}()
    for (obj, entry) in entries(doc)
        addentry!(idx, obj, entry)
    end

    if !isempty(idx)
        ents = prepare_entries(idx, ents, doc)
        if ents.isjoined && has_items(ents.joined)
            ents.has_items = true
            process_entries(io, mime, ents)
        elseif (has_items(ents.exported) || has_items(ents.internal))
            ents.has_items = true
            process_entries(io, mime, ents, "Exported")
            process_entries(io, mime, ents, "Internal")
        end
    end
    return ents
end

function prepare_entries(idx::Dict{Symbol, Any}, ents::Entries, doc::Metadata)
    pageanchors = Dict{Symbol, Dict{String, Int}}([])
    for k in ents.savedconfig.category_order
        haskey(idx, k) || continue
        k in pageanchors || (pageanchors[k] = Dict([]))
        basenames = pageanchors[k]
        for (s, obj) in idx[k]
            ent = entries(doc)[obj]
            if k == :comment
                basename = "comment"
            else
                # adjust basename to be a valid html id
                basename = generate_html_id(string(k == :macro ? macroname(ent) : name(obj)))
            end
            basename in keys(basenames)                  ?
                    anchornum = basenames[basename] += 1 :
                    anchornum = basenames[basename] = 1
            string(k, "_", generate_html_id(s))
            push!(ents, obj, entries(doc)[obj], string(k, "__", basename, ".", anchornum), k)
        end
    end
    return ents
end

file"docs/save.md"
function save(file::AbstractString, modulename::Module, config::Config; args...)
    config = update_config!(deepcopy(config), Dict(args))
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    index_entries = save(file, mime, documentation(modulename), config)
    return index_entries
end
save(file::AbstractString, modulename::Module; args...) = save(file, modulename, Config(); args...)

"""
Saves an *API-Index* to `file`.
"""
function save(file::AbstractString, index::Index, config::Config; args...)
    config = update_config!(deepcopy(config), Dict(args))
    save(file, MIME("text/$(strip(last(splitext(file)), '.'))"), index, config)
end
save(file::AbstractString, index::Index; args...) = save(file, index, Config(); args...)

# Convert's a string to a valid html id
function generate_html_id(s::AbstractString)
    # http://www.w3.org/TR/html4/types.html#type-id
    # ID tokens must begin with a letter ([A-Za-z]) and may be followed by any number of letters,
    # digits ([0-9]), hyphens ("-"), underscores ("_"), colons (":"), and periods (".").
    valid_chars = Set(Char['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
                           'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                           'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
                           'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                           '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                           '-', '_', ':', '.'])

    replace_chars = Set(Char[' ', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',',
                             '/', ';', '<', '=', '>', '?', '@', '[', ']', '^', '`', '{',
                             '¦', '}', '~'])
    skip_chars = Set(Char['!'])

    io = IOBuffer()
    for c in s
        if c in skip_chars
            continue
        elseif c in valid_chars
            write(io, lowercase(string(c)))
        elseif c in replace_chars
            write(io, "_")
        else
            write(io, string(Int(c)))
        end
    end
    # Note: In our case no need to check for begins with letter or is empty
    #  we prepend always the category
    return takebuf_string(io)
end

# Dispatch container for metadata display.
type Meta{keyword}
    content
end

# Cleanup object signatures. Remove method location links.

writeobj(any, entry)       = replace(string(any), ",", ", ")
writeobj(m::Method, entry) = replace(first(split(string(m), " at ")), ",", ", ")

function writeobj(f::Function, entry::Entry{:macro})
    replace(string("@", metadata(entry)[:signature]), ",", ", ")
end

function addentry!{category}(idx, obj, entry::Entry{category})
    section, pair = get!(idx, category, @compat(Tuple{AbstractString, Any})[]), (writeobj(obj, entry), obj)
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
        if startswith(file, root)
            commit = Pkg.Git.readchomp(`rev-parse HEAD`, dir=d)
            return "https://github.com/$u/tree/$commit/"*file[length(root)+2:end]*"#L$line"
        else
            return Base.fileurl(file)
        end
    catch
        return Base.fileurl(file)
    end
end

## Format-specific rendering ------------------------------------------------------------

include("render/plain.jl")
include("render/html.jl")
include("render/md.jl")
