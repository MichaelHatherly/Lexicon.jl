["Markdown rendering."]

"""
Dispatch type for the `rendermacro` function. `name` is a `Symbol`.
"""
immutable RenderMacro{name} end

immutable RenderMacroNameError <: Exception
    msg :: AbstractString
end

"""
Check that a `RenderMacro`'s `name` is a valid identifier.

Throws a `RenderMacroNameError` if the string `s` is not valid.
"""
isvalid(s::AbstractString) = Base.isidentifier(s) ? s :
    throw(RenderMacroNameError("'$(s)' is not a valid rendermacro name."))

"""
Shorthand syntax for defining `RenderMacro{<name>}`s as `RC"<name>"`.

Example

    rendermacro(::RC"header", page)
"""
macro RC_str(str) :(RenderMacro{$(Expr(:quote, symbol(isvalid(str))))}) end

# Extensions to this method are found in `Extensions` module.
rendermacro!(::Union()) = error("Undefined rendermacro.")


immutable EmptyRenderError <: Exception
    msg :: AbstractString
end

type RenderedMarkdown
    outdir   :: UTF8String
    outpages :: Vector{Tuple{AbstractString, AbstractString}}   # outpath, outcontent
end

# Render ContentNodes
function render(children::Vector{ContentNode})
    io = IOBuffer()
    [rendermacro!(io, RenderMacro{child.macroname}(), child)  for child in children]
    return takebuf_string(io)
end

# Render Sections / Preformat / Pages / Page
function render!(outpages::Vector, children::Vector, outdir::UTF8String)
    for child in children
        isempty(child.children) && throw(EmptyRenderError("'$(getnodename(child))': '$(child.name) is empty."))
        if isa(child, Section)
            abs_outdir = joinpath(outdir, child.name)       # new out subdir
            render!(outpages, child.children, abs_outdir)
        elseif isa(child, Preformat)
            for preformatpage in child.children
                outpath = joinpath(outdir, "$(preformatpage.name).md")
                preformatpage.meta[:outpath] = outpath
                push!(outpages, (outpath, preformatpage.data))
            end
        elseif isa(child, Pages)
            render!(outpages, child.children, outdir)
        elseif isa(child, Page)
            outpath = joinpath(outdir, "$(child.name).md")
            child.meta[:outpath] = outpath
            push!(outpages, (outpath, render(child.children)))
        else
            throw(ArgumentError(string("wrong child type: '$(typeof(child))' must be one of: ",
                                       "`Section, Preformat, Pages or Page`")))
        end
    end
end


function markdown(outdir::AbstractString, document::Document)
    abs_outdir = utf8(joinpath(abspath(outdir), document.name))
    outpages = Vector()
    isempty(document.children) && throw(EmptyRenderError("document: '$(document.name) is empty."))

    render!(outpages, document.children, abs_outdir)
    return RenderedMarkdown(abspath(outdir), outpages)
end

"""
!!summary(Write the documentation stored in RenderedMarkdown to disk.)
"""
function save(rmd::RenderedMarkdown; remove_destination=false)
    if ispath(rmd.outdir)
        if remove_destination
            rm(rmd.outdir; recursive=true)
        else
            throw(ArgumentError(string("\n'save(): outdir' exists. `remove_destination=true` ",
                                       "is required to remove it before saving.\n",
                                       "outdir: $(rmd.outdir)\n\n")))
        end
    end
    mkpath(rmd.outdir)
    for (path, content) in rmd.outpages
        pathdir = dirname(path)
        ispath(pathdir) || mkpath(pathdir)
        open(path, "w") do f
            info("writing documentation to $(path)")
            write(f, content)
        end
    end
end

## Helpers
wrapstyle(style::ASCIIString, data) = style in STYLE_TAGS ? "$(style) $(data)" :  "$(style)$(data)$(style)"
