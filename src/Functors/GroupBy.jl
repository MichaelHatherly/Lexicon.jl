module GroupBy

"""
These functors take a single object as their input and must return a key to
group the object by.
"""
GroupBy

using Compat

import Docile:

    Cache

import ..Functors:

    Functor,
    applyf


"""
By default group by the line number and file of each object.

Usage

    GroupBy.Default()

"""
immutable Default <: Functor end

applyf(::Default, x) = Cache.getmeta(x.mod, x.obj)[:textsource]


"""
Group by a user-defined anonymous function that returns a key for
each object.

Usage

    GroupBy.Custom() do x
        # ...
    end

Or without using ``do``-block syntax

    GroupBy.Custom(x -> generate_key(x))

where ``generate_key`` is an arbitrary function used for illustrative purposes.
"""
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, x) = c.func(x)

end
