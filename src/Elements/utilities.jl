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

"""
Assign an id to the given ``node``.

Defaults to the node type and position in ``.children`` vector. A custom id
may be provided by passing a ``Symbol`` to the node constructor.

    document(:myname,
        section(
            :mysection,
        ),
        section(
        )
    )

The ``Node{Document}`` and first ``Node{Section}`` will have custom ids, whereas
the second section will have the generated id ``:Section-2``.
"""
function assign_id!{T}(node::Node{T}, n)
    node.cache[:id] = haskey(node.data, :id) ? node.data[:id] :
        symbol(string(T.name.name, "-", n))
end

"""
Get the vector of symbols that uniquely identify a node in a document tree.
"""
function get_full_id(node::Node)
    haskey(node.cache, :id) || return Symbol[]
    symbols = Symbol[node.cache[:id]]
    while isdefined(node, :parent)
        node = node.parent
        unshift!(symbols, node.cache[:id])
    end
    symbols
end
