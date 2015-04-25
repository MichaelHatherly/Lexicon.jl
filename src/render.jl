## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docile.Interface.Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------
const MDHTAGS = ["#", "##", "###", "####", "#####", "######"]
const MDSTYLETAGS = ["", "*", "**"]
const MD_SUBHEADER_OPTIONS = [:skip, :simple, :category]

"Main configuration use a separate file for documentation of options or keep the info in save ?????"
type Config
    category_order         :: Vector{Symbol}
    include_internal       :: Bool
    mathjax                :: Bool
    mdstyle_header         :: ASCIIString
    mdstyle_objname        :: ASCIIString
    mdstyle_meta           :: ASCIIString
    mdstyle_subheader      :: ASCIIString
    mdstyle_genindex_mod   :: ASCIIString
    md_subheader           :: Symbol
    md_genindex_modprefix  :: ByteString
    md_permalink           :: Bool

    const defaults = Dict{Symbol, Any}([
        (:category_order         , [:module, :function, :method, :type,
                                    :typealias, :macro, :global, :comment]),
        (:include_internal       , true),
        (:mathjax                , false),
        (:mdstyle_header         , "#"),
        (:mdstyle_objname        , "####"),
        (:mdstyle_meta           , "*"),
        (:mdstyle_subheader      , "##"),
        (:mdstyle_genindex_mod   , "##"),
        (:md_subheader           , :simple),
        (:md_genindex_modprefix  , "MODULE: "),
        (:md_permalink           , true)
        ])

    function Config(; args...)
        return update_config!(new(), merge(defaults, Dict(args)))
    end
end

function update_config!(config::Config, args::Dict)
    const fields = fieldnames(Config)
    for (k, v) in args
        try
            k in fields ? setfield!(config, k, v) : warn("Invalid setting: '$(k) = $(v)'.")
        catch err # e.g. TypeError
            warn("Invalid setting: '$(k) = $(v)'. Error: $err")
        end
    end

    for k in [:mdstyle_header, :mdstyle_objname, :mdstyle_meta, :mdstyle_subheader,
                                                                :mdstyle_genindex_mod]
        getfield(config, k) in vcat(MDHTAGS, MDSTYLETAGS) ||
                error("""Invalid mdstyle : config-item `$k -> $(getfield(config, k))`.
                      Valid values: [$(join(vcat(MDHTAGS, MDSTYLETAGS), ", "))].""")

        config.md_subheader in MD_SUBHEADER_OPTIONS ||
                    error("""Invalid md_subheader : config-item `$k -> $(getfield(config, k))`.
                          Valid values: $MD_SUBHEADER_OPTIONS.""")
    end
    return config
end

type Entries
    entries::Vector{@compat(Tuple{Module, Any, AbstractEntry})}
end
Entries() = Entries(@compat(Tuple{Module, Any, AbstractEntry})[])

function push!(ents::Entries, modulename::Module, obj, ent::AbstractEntry)
    push!(ents.entries, (modulename, obj, ent))
end

type Index
    entries::Vector{Entries}
end
Index() = Index(Vector{Entries}[])

function update!(index::Index, ents::Entries)
    push!(index.entries, ents)
end

file"docs/save.md"
function save(file::AbstractString, modulename::Module, config::Config; args...)
    isempty(args) || update_config!(deepcopy(config), Dict(args))
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    index_entries = save(file, mime, documentation(modulename), config)
    return index_entries
end

"""
Saves an *API-Index* to `file`.
"""
function save(file::AbstractString, index_entries::Vector, config::Config; args...)
    isempty(args) || update_config!(deepcopy(config), Dict(args))
    save(file, MIME("text/$(strip(last(splitext(file)), '.'))"), index_entries, config)
end

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

function addentry!{category}(index, obj, entry::Entry{category})
    section, pair = get!(index, category, @compat(Tuple{AbstractString, Any})[]), (writeobj(obj, entry), obj)
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
