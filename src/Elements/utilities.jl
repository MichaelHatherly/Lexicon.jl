["Helper functions."]

"""
Find the value for ``key`` associated with a node ``n``'s configuration.

Returns a ``Nullable{T}`` object. ``isnull`` must be called to determine whether
an object was actually found or not.
"""
function findconfig(n::Node, key::Symbol, T)
    haskey(n.data, key) && return asnull(T, n.data, key)
    # Stage 2: Parent's config.
    while isdefined(n, :parent)
        n = n.parent
        haskey(n.data, key) && return asnull(T, n.data, key)
    end
    Nullable{T}()
end
asnull(T, config, key) = Nullable{T}(convert(T, config[key]))
