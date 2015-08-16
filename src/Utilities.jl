"""
    Utilities
"""
module Utilities

export tryget, submodules, files

tryget(mod, field, default) = isdefined(mod, field) ? getfield(mod, field) : default

"""
    submodules(mod)

> The set of submodules of a module ``mod``.

"""
function submodules(mod :: Module)
    out = Set([mod])
    for name in names(mod, true)
        if isdefined(mod, name)
            object = getfield(mod, name)
            validmodule(mod, object) && union!(out, submodules(object))
        end
    end
    out
end

validmodule(mod :: Module, object :: Module) = object ≠ mod && object ≠ Main
validmodule(:: Module, other)                = false

"""
    files(cond, root)

> Collect all files from a directory matching a condition ``cond``.

By default the file search is recursive. This can be disabled using the keyword
argument ``recursive = false``.
"""
function files(cond, root, out = Set(); recursive = true)
    for f in readdir(root)
        f = joinpath(root, f)
        isdir(f)  && recursive && files(cond, f, out)
        isfile(f) && cond(f)   && push!(out, f)
    end
    out
end

end
