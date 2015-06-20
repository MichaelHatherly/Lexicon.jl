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

import ...Utilities


"""
The default filtering does not discard any objects.
"""
immutable Default <: Functor end

applyf(::Default, x) = true


"""
Filter objects based on their category.

    FilterBy.Categories(:function, :method, :macro)

keeps functions, methods, and macros. All other objects are discarded.
"""
immutable Categories <: Functor
    categories :: Vector{Symbol}
    Categories(cs...) = new(unique(cs))
end

applyf(cat::Categories, x) = Cache.getmeta(x.mod, x.obj)[:category] ∈ cat.categories


"""
Custom filter based on a user defined anonymous function with one argument.

A ``Custom`` filter may be defined using either ``do``-block syntax

    FilterBy.Custom() do x
        test_object(x)
    end

or

    FilterBy.Custom(x -> test_object(x))

``test_object`` is some arbitrary function used for illustrative purposes only.

Return type must be a ``Bool``.
"""
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, x) = c.func(x)

"""
Filter objects to only include those that have be exported from their modules.

Usage

    FilterBy.Exported()

To include only non-exported objects use the ``!`` operator:

    !FilterBy.Exported()

"""
immutable Exported <: Functor end

function applyf(::Exported, x)
    exports = Cache.getmeta(Cache.getmodule(x.mod))[:exports]
    Utilities.name(x.mod, x.obj) ∈ exports
end

end
