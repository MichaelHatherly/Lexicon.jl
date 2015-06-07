# Query Splitting. #

function nullmatch(reg::Regex, text::AbstractString)
    out = match(reg, text)
    out == nothing && return Nullable{RegexMatch}()
    Nullable{RegexMatch}(out)
end

const INTEGER_REGEX = r"\s([-+]?\d+)$"

function splitquery{S <: AbstractString}(text::S)
    m = nullmatch(INTEGER_REGEX, text)
    isnull(m) && return (text, 0)
    convert(S, split(text, INTEGER_REGEX)[1]), parse(Int, m.value.match)
end

# Module Selection. #

"""
Convert object to it's defining module. Discard when no module can be found.
"""
:modulesof

function modulesof(func::Function)
    mods = Module[]
    if isgeneric(func)
        for m in methods(func)
            push!(mods, getmod(m.func.code))
        end
    else
        push!(mods, getmod(func.code))
    end
    mods
end
modulesof(meth::Method) = Module[getmod(meth.func.code)]
modulesof(mod::Module)  = Module[mod]
modulesof(dt::DataType) = Module[getmod(dt.name)]
modulesof(other)        = Module[]

# Helper for ``modulesof`` methods.
getmod(obj) = getfield(obj, :module)

"""
Given a vector of object, convert it to a vector of ``Module`` object where
elements are replaced by their defining modules.
"""
function modules(vector::Vector)
    mods = Set{Module}()
    for v in vector, m in modulesof(v)
        push!(mods, m)
    end
    mods
end

# Tuple handling. #

if VERSION < v"0.4-dev+4319"
    to_tuple_type(t) = t
else
    to_tuple_type(t::Tuple) = Tuple{t...}
    to_tuple_type(t)        = t
end

# Return types. #

if VERSION < v"0.4-dev+4908"
    const __typeinf__ = Base.typeinf
else
    const __typeinf__ = Core.Inference.typeinf
end

if VERSION < v"0.4-dev+4319"
    const __env__ = ()
else
    const __env__ = Core.svec()
end

returned(obj) = __typeinf__(obj.func.code, obj.sig, __env__)[2]
