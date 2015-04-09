## Extending docs format support --------------------------------------------------------

parsedocs(ds::Docs{:md}) = Markdown.parse(data(ds))

## Common -------------------------------------------------------------------------------

md"""
Write the documentation stored in `modulename` to the specified `file`
in the format guessed from the file's extension.

If MathJax support is required then the optional keyword argument
`mathjax::Bool` may be given. MathJax uses `\(...\)` for in-line maths
and `\[...\]` or `$$...$$` for display equations.

To exclude documentation for non-exported objects, the keyword argument
`include_internal::Bool` should be set to `false`. This is only supported
for `markdown`.

Currently supported formats: `HTML`, and `markdown`.

#### Markdown Specific

**Markdown optional configuration**

The format `markdown` accepts an optional configurtion dictionary which can be used to adjust
the style of defined items in the autogenerated api documentation.

* Below are the DEFAULT_MDSTYLE, HTAGS (Valid Header Tags), STYLETAGS (Valid Style Tags)

```julia
const DEFAULT_MDSTYLE = Dict{Symbol, ByteString}([
  (:header         , "#"),
  (:objname        , "####"),
  (:meta           , "**"),
  (:exported       , "##"),
  (:internal       , "##"),
])

const HTAGS = ["#", "##", "###", "####", "#####", "######"]
const STYLETAGS = ["", "*", "**"]
```

EXAMPLE USAGE:

```julia
using Lexicon
const MDSTYLE = Dict{Symbol, ByteString}([
  (:header         , "#"),
  (:objname        , "###"),
  (:meta           , "*"),
  (:exported       , "##"),
  (:internal       , "##"),
])
plmain = startgenidx(joinpath("docs/api/genindex.md")
save("docs/api/Lexicon.md", Lexicon, plmain, MDSTYLE)

# if the API Index page should also be saved one must call afterwards
savegenidx(plmain)

```

**Markdown output optional Permalink**

The format `markdown` accepts an optional keyword argument: `permalink::Bool` (default: true)
If `permalink=true` an additional **¶** will be added after the `:objname` with the permanlink
to that definition (in the autogenerated api documentation).

*Note:* for the permalink added html anchors have all an additional class attribute called: `headerfix`
which can be used for example to fix html pages generated with MkDocs.

**Markdown join multi-Pkg / Modules in one API-Index page**

It is possible to join multiple Pkg / Modules in one API-Index page.

```julia
using Lexicon, Docile
plmain = startgenidx("genindex.md"; headerstyle = "##", modnamestyle = "**")
save("api/Lexicon.md", Lexicon, plmain)
save("api/Docile.md", Docile, plmain)
savegenidx(plmain)

```

Writes files like this:

```
├── api
│   ├── Docile.md
│   └── Lexicon.md
└── genindex.md       > index to both

```

**Markdown API-Index page**

The autogenerated API-Index will use the *first* line of an docstring as the info in the
Index page, because of this the *first* line  should be only a *short* sentence.


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
plmain = startgenidx("genindex.md"; headerstyle = "#", modnamestyle = "##")
save("docs/api/Lexicon.md", Lexicon, plmain)
savegenidx(plmain)
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
function save(file::String, modulename::Module, plmain;
                            mathjax = false, include_internal = true, permalink::Bool = true)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename), plmain; mathjax = mathjax,
        include_internal = include_internal, permalink = permalink)
end

function save(file::String, modulename::Module, plmain, mdstyle::Dict{Symbol, ByteString};
                            mathjax = false, include_internal = true, permalink::Bool = true)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    mime != MIME("text/md") && error("`mdstyle` is only supported for `markdown`: Got mime: $mime")
    save(file, mime, documentation(modulename), plmain, mdstyle; mathjax = mathjax,
        include_internal = include_internal, permalink = permalink)
end

function save(file::String, modulename::Module; mathjax = false, include_internal = true)
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, documentation(modulename); mathjax = mathjax,
        include_internal = include_internal)
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
