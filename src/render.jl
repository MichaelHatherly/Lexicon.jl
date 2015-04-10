## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------

md"""
Default configuration dictionary.

**Registered Options**

*General Options*

* `:mathjax` (Bool default: false): If MathJax support is required then pass `(:mathjax, true)`
  in a `config` dictionary to the `save` method. MathJax uses `\(...\)` for in-line maths and
  `\[...\]` or `$$...$$` for display equations.

* `:include_internal` (Bool default: true): To exclude documentation for non-exported objects,
  pass `(:include_internal, false)` in a `config` dictionary to the `save` method.
  The `html` format requires this to be true `(:include_internal, true)`

*MarkDown only Options*

* `:mdstyle_header` (ASCIIString default: "#"): Output style for the Header.
  Valid mdstyles are: ["#", "##", "###", "####", "#####", "######", "", "*", "**"]

* `:mdstyle_objname` (ASCIIString default: "###"): for Valid mdstyles see: `:mdstyle_header` above.

* `:mdstyle_meta` (ASCIIString default: "*"): for Valid mdstyles see: `:mdstyle_header` above.

* `:mdstyle_exported` (ASCIIString default: "##"): for Valid mdstyles see: `:mdstyle_header` above.

* `:mdstyle_internal` (ASCIIString default: "##"): for Valid mdstyles see: `:mdstyle_header` above.


Any option can be user adjusted by passing a `config` dictionary to the `save` method.

EXAMPLE:

```julia
using Lexicon

const myconf = Dict([
    (:mathjax, true),
    (:mdstyle_header, "##")
])

save("Lexicon.md", Lexicon, myconf)
```
"""
const DEFAULT_CONFIG = Dict{Symbol, Any}([
    # General Options
    (:mathjax               , false),
    (:include_internal      , true),
    # MarkDown only Options
    (:mdstyle_header        , "#"),
    (:mdstyle_objname       , "###"),
    (:mdstyle_meta          , "*"),
    (:mdstyle_exported      , "##"),
    (:mdstyle_internal      , "##"),
])


"""
Write the documentation stored in `modulename` to the specified `file`
in the format guessed from the file's extension.

For configuration options see the documentation of the `DEFAULT_CONFIG`.

Currently supported formats are: `HTML`, and `markdown`.

**MkDocs**

Beginning with Lexicon 0.1 you can save documentation as pre-formatted
markdown files which can then be post-processed using 3rd-party programs
such as the static site generator [MkDocs](http://www.mkdocs.org).

For details on how to build documentation using MkDocs please consult their
detailed guides and the Docile and Lexicon packages. A more customized build
process can be found in the Sims.jl package.

**Example:**

The documentation for this package was created in the following manner.
All commands are run from the top-level folder in the package.

```julia
using Lexicon
save("docs/api/Lexicon.md", Lexicon)
run(`mkdocs build`)

```

From the command line, or using `run`, push the `doc/site` directory
to the `gh-pages` branch on the package repository after pushing the
changes to the `master` branch.

```
git add .
git commit -m "documentation changes"
git push origin master
git subtree push --prefix docs/build origin gh-pages

```

If this is the first push to the branch then the site may take some time
to become available. Subsequent updates should appear immediately. Only
the contents of the `doc/site` folder will be pushed to the branch.

The documentation will be available from
`https://USER_NAME.github.io/PACKAGE_NAME/FILE_PATH.html`.

"""
function save(file::String, modulename::Module, config::Dict{Symbol, Any} = DEFAULT_CONFIG)
    reg_keys = keys(DEFAULT_CONFIG)
    if config != DEFAULT_CONFIG
        for k in keys(config)
            k in reg_keys || error("Invalid 'config' key:  `$k`. Valid keys: [$(join(reg_keys, ", "))].")
        end
        for (k, v) in DEFAULT_CONFIG
            k in keys(config) || (config[k] = v)
        end
    end
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename), config)
end

const CATEGORY_ORDER = [:module, :function, :method, :type, :macro, :global]

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

## Format-specific rendering ------------------------------------------------------------

include("render/plain.jl")
include("render/html.jl")
include("render/md.jl")
