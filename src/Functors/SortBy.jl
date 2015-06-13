module SortBy

"""
These functors take two objects as their input and return ``true`` if the first
is "smaller than" the second otherwise ``false``.
"""
SortBy

using Compat

import Docile:

    Cache

import ..Functors:

    Functor,
    applyf


# No sorting.
immutable Default <: Functor end

applyf(::Default, a, b) = true


# Sort by the string representation of an object.
immutable StringName <: Functor end

applyf(::StringName, a, b) = string(a.obj) < string(b.obj)


# Strict ordering by vector of categories.
immutable CategoryOrder <: Functor
    order :: Vector{Symbol}
    CategoryOrder(cs...) = new(unique(cs))
end

function applyf(c::CategoryOrder, a, b)
    x = findfirst(c.order, Cache.getmeta(a.mod, a.obj)[:category])
    y = findfirst(c.order, Cache.getmeta(b.mod, b.obj)[:category])
    (x == 0 || y == 0) && throw(ErrorException("'$(a.obj)' has no order in $(c.order)."))
    x < y
end


# Passing any appropriate function.
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, a, b) = c.func(a, b)

end
