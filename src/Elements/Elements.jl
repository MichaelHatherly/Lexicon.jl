module Elements

"""

"""
Elements

using Compat

export document, section, page, docs, config

abstract NodeT

immutable Document <: NodeT end
immutable Section  <: NodeT end
immutable Page     <: NodeT end
immutable Docs     <: NodeT end

type Node{T <: NodeT}
    children :: Vector
    data     :: Dict{Symbol, Any}
    parent   :: Node
    Node() = new(Any[], Dict{Symbol, Any}())
    Node(children, data) = new(children, data)
end

function (==){T}(a::Node{T}, b::Node{T})
    length(a.children) == length(b.children) || return false
    for (x, y) in zip(a.children, b.children)
        x == y || return false
    end
    length(a.data) == length(b.data) || return false
    for (x, y) in zip(a.data, b.data)
        x == y || return false
    end
    # Don't check the parent node. Infinite loop!
    true
end
(==){S, T}(a::Node{S}, b::Node{T}) = false

config(; kwargs...) = config(kwargs)
config(args)        = Dict{Symbol, Any}(args)

document(args...; kwargs...) = build!(Document, args, config(kwargs))

section(args...; kwargs...) = (Section, args, config(kwargs))
page(args...; kwargs...)    = (Page,    args, config(kwargs))
docs(args...; kwargs...)    = (Docs,    args, config(kwargs))

function build!(node::Node, args, kwargs)
    for arg in args update!(node, arg) end
    update!(node, kwargs)
    node
end
build!(T, args, kwargs) = build!(Node{T}(), args, kwargs)

function update!(n::Node, child::Tuple)
    out = build!(child...); setparent!(n, out)
    push!(n.children, out)
end
update!(n::Node{Page}, x::Union(AbstractString, Node{Docs})) = push!(n.children, x)
update!(n::Node{Docs}, x::Union(AbstractString, Module))     = push!(n.children, x)
update!(n::Node,       x::Dict)                              = merge!(n.data, x)
update!(n::Node,       x::Symbol)                            = n.data[:id] = x

update!{S, T}(n::Node{S}, t::T) = throw(ArgumentError("Can't add '$(T)' to '$(S)' node."))

setparent!(n::Node{Document}, x::Node{Section})                    = x.parent = n
setparent!(n::Node{Section},  x::Union(Node{Section}, Node{Page})) = x.parent = n
setparent!(n::Node{Page},     x::Node{Docs})                       = x.parent = n

setparent!{S, T}(n::Node{S}, x::Node{T}) = throw(ArgumentError("Can't nest '$(T)' in '$(S)'."))

## Display methods. For debugging. ##

const INDENT_WIDTH = 4

pad(indents)   = (" "^INDENT_WIDTH)^indents
maxwidth(data) = maximum([length(string(k)) for k in keys(data)])

function Base.writemime{T}(io::IO, mime::MIME"text/plain", n::Node{T}, indent = 0)
    println(io, pad(indent), rename(T), "(")
    for child in n.children
        inner(io, mime, child, indent + 1)
    end
    isempty(n.data) || showconfig(io, n, indent + 1)
    println(io, pad(indent), indent == 0 ? ")" : "),")
end

function showconfig(io, n, indent)
    width = maxwidth(n.data)
    for (k, v) in n.data
        key = string(pad(indent), k, " "^(width - length(string(k))))
        println(io, key, " = ", repr(v), ",")
    end
end

inner(io::IO, mime::MIME"text/plain", n::Node, indent) = writemime(io, mime, n, indent)
inner(io::IO, ::MIME"text/plain", v, indent)           = println(io, pad(indent), repr(v), ',')

rename(T) = lowercase(last(split(string(T), '.')))

end
