const INDENT_WIDTH = 4
pad(indents) = (" "^INDENT_WIDTH)^indents

# Write a mkdocs yaml file: takes settings from ``rmd`` RenderedMarkdown
function writemkdocs(rmd)
    abs_path = joinpath(dirname(rmd.outdir), "mkdocs.yml")
    pathdir = dirname(abs_path)
    ispath(pathdir) || mkpath(pathdir)
    open(abs_path, "w") do f
        info("writing `MkDocs` yaml file to $(abs_path)")
        writemkdocs!(f, rmd)
    end
end

function writemkdocs!(io::IO, rmd)
    keys = [:site_name, :repo_url, :site_description, :site_author, :docs_dir]
    optionalkeys = [:theme, :theme_dir, :copyright, :google_analytics, :markdown_extensions]
    conf = deepcopy(rmd.document.data)
    conf[:docs_dir] = basename(rmd.outdir)
    haskey(conf, :site_name) || (conf[:site_name] = conf[:title])
    for k in keys
        haskey(conf, k) || throw(ArgumentError("Document '$(conf[:title])' has no config key ':$k'."))
    end
    for k in optionalkeys
        haskey(conf, k) && push!(keys, k)
    end
    writemkdocs(io, conf, keys)
    println(io, "pages:")
    writemkdocs(io, -1, rmd.layout[1][2])
    println(io)
end

function writemkdocs(io::IO, conf::Dict{Symbol, Any}, keys::Vector)
    maxwidth = maximum([length(string(k)) for k in keys]) + 2
    println(io, "# This MkDocs configuration file is generated using the `Lexicon.jl` julia package.")
    println(io)
    for k in keys
        k == :markdown_extensions                  ?
            writemkdocs(io::IO, conf[k], maxwidth) :
            println(io, string(rpad("$(string(k)):", maxwidth), conf[k]))
    end
end

function writemkdocs(io::IO, markdown_extensions::Vector, maxwidth::Int)
    println(io)
    println(io, rpad("markdown_extensions:", maxwidth))
    for ext in markdown_extensions
        isa(ext, Tuple)                    ?
            writemkdocs(io, ext, maxwidth) :
            println(io, string(pad(1), "- $(ext)"))
    end
    println(io)
end

function writemkdocs(io::IO, ext::Tuple, maxwidth::Int)
    println(io, string(pad(1), "- $(ext[1]):"))
    for (opt, v) in ext[2]
        println(io, string(pad(2), "$opt: $v"))
    end
end

function writemkdocs(io::IO, indents::Int, layout::Vector)
    maxwidth = maximum([length(string(x[1])) for x in filter((y) -> !isa(y[2], Vector), layout)]) + 2
    indents += 1
    for ent in layout
        if isa(ent[2], Vector)
            println(io, pad(indents), "- $(ent[1]):")
            writemkdocs(io::IO, indents, ent[2])
        else
            println(io, string(pad(indents), "- ", rpad("$(ent[1]):", maxwidth), ent[2]))
        end
    end
end
