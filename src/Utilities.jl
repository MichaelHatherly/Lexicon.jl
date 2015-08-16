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
function submodules(mod :: Module, out = Set())
    push!(out, mod)
    for name in names(mod, true)
        if isdefined(mod, name)
            object = getfield(mod, name)
            validmodule(mod, object) && submodules(object, out)
        end
    end
    out
end

validmodule(a :: Module, b :: Module) = b ≠ a && b ≠ Main
validmodule(a, b) = false

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

"""
    filehook(f, file)

> Run a function ``f(file)`` whenever ``file`` is changed.

Returns a function that can be called to abort the watcher.

**Usage:**

```julia
fn = filehook("foobar.md") do
    # ...
end
# ...
fn()
```
"""
function filehook(f, file)
    s = Ref(true)
    @async while true
        watch_file(file)
        s[] ? f(file) : return
    end
    () -> (s[] && (s[] = false; touch(file)); file)
end

end
