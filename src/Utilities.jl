"""
    Utilities
"""
module Utilities

export tryget, submodules

tryget(mod, field, default) = isdefined(mod, field) ? getfield(mod, field) : default

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

end
