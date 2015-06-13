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


# Group by the line number and file.
immutable Default <: Functor end

applyf(::Default, x) = Cache.getmeta(x.mod, x.obj)[:textsource]


# Passing any appropriate function.
immutable Custom <: Functor
    func :: Function
end

applyf(c::Custom, x) = c.func(x)

end
