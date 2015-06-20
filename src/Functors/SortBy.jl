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


"""
By default we do not sort any objects.

Usage

    SortBy.Default()

"""
immutable Default <: Functor end

applyf(::Default, a, b) = false


"""
Sort by the ``string`` representation of an object.

Usage

    SortBy.StringName()

"""
immutable StringName <: Functor end

applyf(::StringName, a, b) = string(a.obj) < string(b.obj)


"""
Strict ordering by a vector of categories.

*Note:* When an object's category is not listed then an error will be thrown.

Usage

    SortBy.CategoryOrder(:type, :global, :bitstype)

will sort types (``abstract``, ``type``, and ``immutable``) first, followed by
globals, and finally ``bitstype`` types.
"""
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


"""
Any appropriate user-defined anonymous function can be used to sort objects.

The function must take two arguments that are compared to decide if the first is
smaller than the second.

Usage

    SortBy.Custom() do a, b
        # ...
    end

or without ``do``-syntax

    SortBy.Custom((a, b) -> sorting_method(a, b))

where ``sorting_method`` is for illustrative purposes only.

The provided function **must** have a ``Bool`` return type.
"""
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, a, b) = c.func(a, b)

end
