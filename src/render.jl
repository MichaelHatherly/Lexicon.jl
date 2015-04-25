## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docile.Interface.Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------
const MDHTAGS = ["#", "##", "###", "####", "#####", "######"]
const MDSTYLETAGS = ["", "*", "**"]

type Config
    category_order   :: Vector{Symbol}
    include_internal :: Bool
    mathjax          :: Bool
    mdstyle_header   :: ASCIIString
    mdstyle_objname  :: ASCIIString
    mdstyle_meta     :: ASCIIString
    mdstyle_exported :: ASCIIString
    mdstyle_internal :: ASCIIString

    const fields   = fieldnames(Config)
    const defaults = Dict{Symbol, Any}([
        (:category_order    , [:module, :function, :method, :type,
                               :typealias, :macro, :global, :comment]),
        (:include_internal , true),
        (:mathjax          , false),
        (:mdstyle_header   , "#"),
        (:mdstyle_objname  , "###"),
        (:mdstyle_meta     , "*"),
        (:mdstyle_exported , "##"),
        (:mdstyle_internal , "##")
        ])

    function Config(; args...)
        this = new()
        for (k, v) in merge(defaults, Dict(args))
            try
                k in fields ? setfield!(this, k, v) : warn("Invalid setting: '$(k) = $(v)'.")
            # e.g. catch TypeError
            catch err
                warn("Invalid setting: '$(k) = $(v)'. Error: $err")
            end
        end
        # Validations
        for k in [:mdstyle_header, :mdstyle_objname, :mdstyle_meta, :mdstyle_exported, :mdstyle_internal]
           getfield(this, k) in vcat(MDHTAGS, MDSTYLETAGS) ||
                                error("""Invalid mdstyle value: config-item `$k -> $(getfield(this, k))`.
                                        Valid values: [$(join(vcat(MDHTAGS, MDSTYLETAGS), ", "))].""")
        end
        return this
    end
end


type Entries
    entries::Vector{@compat(Tuple{Module, Any, AbstractEntry})}
end
Entries() = Entries(@compat(Tuple{Module, Any, AbstractEntry})[])

function push!(ents::Entries, modulename::Module, obj, ent::AbstractEntry)
    push!(ents.entries, (modulename, obj, ent))
end

file"docs/save.md"
function save(file::AbstractString, modulename::Module; args...)
    config = Config(; args...)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename), config)
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
