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
