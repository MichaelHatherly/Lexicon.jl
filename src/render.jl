## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------
const MDHTAGS = ["#", "##", "###", "####", "#####", "######"]
const MDSTYLETAGS = ["", "*", "**"]

type Config
    # General Options
    category_order   :: Vector{Symbol}
    include_internal :: Bool
    # Html only Options
    mathjax          :: Bool
    # MarkDown only Options
    mdstyle_header   :: ASCIIString
    mdstyle_objname  :: ASCIIString
    mdstyle_meta     :: ASCIIString
    mdstyle_exported :: ASCIIString
    mdstyle_internal :: ASCIIString

    const fields   = fieldnames(Config)
    const defaults = Dict{Symbol, Any}([
        (:category_order   , [:module, :function, :method, :type, :typealias, :macro, :global,
                                                                                    :comment]),
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

file"docs/save.md"
function save(file::String, modulename::Module; args...)
    config = Config(; args...)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename), config)
end

type Entries
    entries::Vector{(Module, Any, Entry)}
end
Entries() = Entries((Module, Any, Entry)[])

function push!(ents::Entries, modulename::Module, obj, ent::Entry)
    push!(ents.entries, (modulename, obj, ent))
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
    section, pair = get!(index, category, (String, Any)[]), (writeobj(obj, entry), obj)
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

## Utilities
if VERSION < v"0.4-"
    # returns the index of the previous element for which the function returns true, or zero if it never does
    function findprev(testf::Function, A, start)
        for i = start:-1:1
            testf(A[i]) && return i
        end
        0
    end
    findlast(testf::Function, A) = findprev(testf, A, length(A))
end

# Return a relative filepath to path either from the current directory or from an optional start directory.
# This is a path computation: the filesystem is not accessed to confirm the existence or nature of path or startpath.
# Inspired by python's relpath
function relpath(path::ByteString, startpath::ByteString = ".")
    isempty(path) && throw(ArgumentError("`path` must be specified"))
    isempty(startpath) && throw(ArgumentError("`startpath` must be specified"))
    curdir = "."
    pardir = ".."
    path == startpath && return curdir

    path_arr  = split(abspath(path),      Base.path_separator_re)
    start_arr = split(abspath(startpath), Base.path_separator_re)

    i = 0
    while i < min(length(path_arr), length(start_arr))
        i += 1
        if path_arr[i] != start_arr[i]
            i -= 1
            break
        end
    end

    pathpart = join(path_arr[i+1:findlast(x -> !isempty(x), path_arr)], Base.path_separator)
    prefix_num = findlast(x -> !isempty(x), start_arr) - i - 1
    if prefix_num >= 0
        prefix = pardir * Base.path_separator
        relpath_ = isempty(pathpart)                                      ?
            (prefix^prefix_num) * pardir                                  :
            (prefix^prefix_num) * pardir * Base.path_separator * pathpart
    else
        relpath_ = pathpart
    end
    return isempty(relpath_) ? curdir :  relpath_
end

## Format-specific rendering ------------------------------------------------------------

include("render/plain.jl")
include("render/html.jl")
include("render/md.jl")
