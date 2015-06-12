["Helper functions."]

"""
Find the value for ``key`` associated with a node ``n``'s configuration.

Returns a ``Nullable{T}`` object. ``isnull`` must be called to determine whether
an object was actually found or not.
"""
function findconfig(n::Node, key::Symbol, T)
    haskey(n.data, key) && return asnull(T, n.data, key)
    while isdefined(n, :parent)
        n = n.parent
        haskey(n.data, key) && return asnull(T, n.data, key)
    end
    Nullable{T}()
end
asnull(T, config, key) = Nullable{T}(convert(T, config[key]))

set_root_cache!(node::Node, key::Symbol, value) = getroot(node).cache[key] = value
push_root_cache!(node::Node, key::Symbol, value) = push!(getroot(node).cache[key], value)
append_root_cache!(node::Node, key::Symbol, value) = append!(getroot(node).cache[key], value)

function getroot(node::Node)
    while isdefined(node.parent)
        node = node.parent
    end
    node
end
