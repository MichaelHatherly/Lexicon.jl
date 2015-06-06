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

getmod(obj) = getfield(obj, :module)

function modules(vector::Vector)
    mods = Set{Module}()
    for v in vector, m in modulesof(v)
        push!(mods, m)
    end
    mods
end
