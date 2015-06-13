module Functors

"""
Grouping, filtering, and sorting.
"""
Functors

using Compat


abstract Functor


immutable And{L, R} <: Functor
    left  :: L
    right :: R
end

(&){L <: Functor, R <: Functor}(left::L, right::R) = And{L, R}(left, right)

applyf(and::And, x)    = applyf(and.left, x)    && applyf(and.right, x)
applyf(and::And, a, b) = applyf(and.left, a, b) && applyf(and.right, a, b)


immutable Or{L, R} <: Functor
    left  :: L
    right :: R
end

(|){L <: Functor, R <: Functor}(left::L, right::R) = Or{L, R}(left, right)

applyf(or::Or, x)    = applyf(or.left, x)    || applyf(or.right, x)
applyf(or::Or, a, b) = applyf(or.left, a, b) || applyf(or.right, a, b)


immutable Not{F} <: Functor
    functor :: F
end

(!){F <: Functor}(functor::F) = Not{F}(functor)

applyf(not::Not, x)    = !not.functor(x)
applyf(not::Not, a, b) = !not.functor(a, b)


if VERSION >= v"0.4-dev"
    Base.call(f::Functor, x)    = applyf(f, x)
    Base.call(f::Functor, a, b) = applyf(f, a, b)
end


include("GroupBy.jl")
include("FilterBy.jl")
include("SortBy.jl")

end
