module FilterBy

"""
These functors take a single object as their input and return ``true`` if the
object should be included otherwise ``false``.
"""
FilterBy

using Compat

import Docile:

    Cache

import ..Functors:

    Functor,
    applyf


# No filtering.
immutable Default <: Functor end

applyf(::Default, x) = true


# Only objects from a set of categories.
immutable Categories <: Functor
    categories :: Vector{Symbol}
    Categories(cs...) = new(unique(cs))
end

applyf(cat::Categories, x) = Cache.getmeta(x.mod, x.obj)[:category] ∈ cat.categories


# Passing any appropriate function.
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, x) = c.func(x)

end
