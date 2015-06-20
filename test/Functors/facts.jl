require(joinpath(dirname(@__FILE__), "FunctorTestModule.jl"))

import FunctorTestModule

import Lexicon.Functors:

    Functor,
    Chained,
    GroupBy,
    FilterBy,
    SortBy,
    applyf

import Lexicon.Compiler:

    ObjectPair,
    makesorter

import Docile.Cache

objectpairs(m) = [ObjectPair(m, o) for o in sort(Cache.objects(m), by = obj -> string(obj))]

name(x::Method)   = x.func.code.name
name(d::DataType) = d.name.name

facts("Functors.") do
    context("GroupBy.") do

        objects  = objectpairs(FunctorTestModule)
        filename = joinpath(dirname(@__FILE__), "FunctorTestModule.jl")

        # Default should return the tuple of line number and filename.
        g1 = GroupBy.Default()

        for (line, pair) in zip([3, 6, 9, 9, 12, 15, 18], objects)
            @fact applyf(g1, pair) => (line, filename)
        end

        # Custom should group by the symbolic object name.
        g2 = GroupBy.Custom(x -> name(x.obj))

        for (sym, pair) in zip([:D_1, :D_2, :f_1, :f_1, :f_2, :g_1, :g_2], objects)
            @fact applyf(g2, pair) => sym
        end
    end

    context("FilterBy.") do

        objects = objectpairs(FunctorTestModule)

        # By default we don't filter anything.
        f1 = FilterBy.Default()

        for obj in objects
            @fact applyf(f1, obj) => true
        end

        # Pick only methods and types, ie. everything from the module in this case.
        f2 = FilterBy.Categories(:method, :type)

        for obj in objects
            @fact applyf(f2, obj) => true
        end

        # Pick only the types.
        f3 = FilterBy.Categories(:type)

        for (res, obj) in zip([true, true, false, false, false, false, false], objects)
            @fact applyf(f3, obj) => res
        end

        # Pick only the methods.
        f4 = FilterBy.Categories(:method)

        for (res, obj) in zip([false, false, true, true, true, true, true], objects)
            @fact applyf(f4, obj) => res
        end

        # Pick none of the available objects.
        f5 = FilterBy.Categories(:global, :macro, :bitstype)

        for obj in objects
            @fact applyf(f5, obj) => false
        end

        # Pick only objects with a 2 in their name.
        f6 = FilterBy.Custom(x -> contains(string(name(x.obj)), "2"))

        for (res, obj) in zip([false, true, false, false, true, false, true], objects)
            @fact applyf(f6, obj) => res
        end

        # Pick only exported objects.
        f7 = FilterBy.Exported()

        for (res, obj) in zip([true, false, true, true, false, true, false], objects)
            @fact applyf(f7, obj) => res
        end

        # Pick only non-exported objects.
        f8 = !FilterBy.Exported()

        for (res, obj) in zip([false, true, false, false, true, false, true], objects)
            @fact applyf(f8, obj) => res
        end
    end

    context("SortBy.") do

        objects = objectpairs(FunctorTestModule)

        # Don't sort by default.
        s1 = makesorter(SortBy.Default())

        for (ind, obj) in zip(1:7, sort(objects, lt = s1))
            @fact objects[ind] => obj
        end

        # Category Ordering, methods then types.
        s2 = makesorter(SortBy.CategoryOrder(:method, :function, :type))

        for (ind, obj) in zip([3, 4, 5, 6, 7, 1, 2], sort(objects, lt = s2))
            @fact objects[ind] => obj
        end

        # By in reverse by the object's lowercase name.
        s3 = SortBy.Custom() do a, b
            lowercase(string(name(a.obj))) >= lowercase(string(name(b.obj)))
        end |> makesorter

        for (ind, obj) in zip([7, 6, 5, 4, 3, 2, 1], sort(objects, lt = s3))
            @fact objects[ind] => obj
        end
    end

    context("Compositions.") do
        f1 = FilterBy.Categories(:method) & FilterBy.Custom() do x
            string(name(x.obj))[1] == 'f'
        end
        f2 = FilterBy.Categories(:type) | FilterBy.Custom() do x
            string(name(x.obj))[1] == 'g'
        end
        f3 = !FilterBy.Categories(:type)

        objects = objectpairs(FunctorTestModule)

        # Only methods starting with the letter 'f'.
        for (res, obj) in zip([false, false, true, true, true, false, false], objects)
            @fact applyf(f1, obj) => res
        end
        # Types or objects starting with the letter 'g'.
        for (res, obj) in zip([true, true, false, false, false, true, true], objects)
            @fact applyf(f2, obj) => res
        end
        # Not objects of category ``:type``.
        for (res, obj) in zip([false, false, true, true, true, true, true], objects)
            @fact applyf(f3, obj) => res
        end

        # Sort by the reverse of category ordering methods, then types.
        # When the same, then sort by negation of the object name.
        c1 = Chained(
            !SortBy.CategoryOrder(:method, :type),
            !SortBy.StringName()
            ) |> makesorter

        for (ind, obj) in zip([2, 1, 7, 6, 5, 4, 3], sort(objects, lt = c1))
            @fact objects[ind] => obj
        end
    end
end
