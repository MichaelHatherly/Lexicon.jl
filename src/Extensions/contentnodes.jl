["Page content nodes: types, constructures, renderer related to document page content sub-tree."]

# Title
type Title <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: AbstractString
end
title(s::AbstractString; cargs...) = Title(:title, PreConfig(; cargs...), NullPage(), s)

function Render.rendermacro!(io::IO, ::RC"title", child::ContentNode)
    println(io, wrapstyle(child.config.style_title, child.data))
    println(io)
end


# Header
type Header <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: AbstractString
end
header(s::AbstractString; cargs...) = Header(:header, PreConfig(; cargs...), NullPage(), s)

function Render.rendermacro!(io::IO, ::RC"header", child::ContentNode)
    println(io, wrapstyle(child.config.style_header, child.data))
    println(io)
end


# SubHeader
type SubHeader <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: AbstractString
end
subheader(s::AbstractString; cargs...) = SubHeader(:subheader, PreConfig(; cargs...), NullPage(), s)

function Render.rendermacro!(io::IO, ::RC"subheader", child::ContentNode)
    println(io, wrapstyle(child.config.style_subheader, child.data))
    println(io)
end


# Text
type Text <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: AbstractString
end
text(s::AbstractString; cargs...) = Text(:text, PreConfig(; cargs...), NullPage(), s)

function Render.rendermacro!(io::IO, ::RC"text", child::ContentNode)
    println(io, child.data)
    println(io)
end


# TextFile
type TextFile <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: AbstractString
end

function textfile(path::AbstractString; cargs...)
    filename = abspath(path)
    isfile(filename) || throw(ArgumentError("Unknown 'manual(...)' file: $(filename)"))
    return TextFile(:textfile, PreConfig(; cargs...), NullPage(), readall(filename))
end

function Render.rendermacro!(io::IO, ::RC"textfile", child::ContentNode)
    println(io, child.data)
    println(io)
end


# ObjList
type ObjList <: ContentNode
    macroname   :: Symbol
    config      :: ConfigNode
    parent      :: PageNode
    data        :: Vector         # list of documented objects e.g. objs = Docile.Cache.objects(Lexicon)
end
objs(objects::Vector; cargs...) = ObjList(:objs, PreConfig(; cargs...), NullPage(), objects)

function objs(m::Module, category::Symbol; cargs...)    # category: meta category: e.g. :method
    objects = Cache.objects(m)
    filter!((obj) -> Cache.getmeta(m, obj)[:category]== category, objects)
    return ObjList(:objs, PreConfig(; cargs...), NullPage(), objects)
end

function Render.rendermacro!(io::IO, ::RC"objs", child::ContentNode)
    println("\n\n render:ObjList TODO: proper render inclusive config settings: ", typeof(child))
    # TODO: proper render inclusive config settings
    println(io, "STILL MISSING: TODO: proper render inclusive config settings")
    for obj in child.data
        println(io, obj)
        println(io)
    end
end
