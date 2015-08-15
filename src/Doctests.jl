"""
    Doctests
"""
module Doctests

using ..Utilities

import Base.Docs: TypeDoc, FuncDoc
import Base.Markdown: MD, Code


@enum Status PASSED FAILED

type Result
    modname :: Module
    object  :: Any
    status  :: Status
    data    :: Any
    source  :: Code
end

# TODO: better printing.
function Base.writemime(io :: IO, mime :: MIME"text/plain", res :: Result)
    header =
    """
    +++
    Object: $(res.object)
    Status: $(res.status)
    """
    extra =
    """
    Result: $(res.data)
    Source:

    ```
    $(res.source.code)
    ```
    """
    println(io, header)
    res.status == FAILED && println(io, extra)
end

type Results
    modname :: Module
    results :: ObjectIdDict
end

function Base.writemime(io :: IO, mime :: MIME"text/plain", res :: Results)
    println(io, "\n", res.modname, " test results:\n")
    for (k, v) in sort(collect(res.results), by = x -> string(x[1]))
        for each in v
            writemime(io, mime, each)
        end
    end
end

function doctest(mod :: Module)
    out = ObjectIdDict()
    for (k, v) in tryget(mod, :__META__, ObjectIdDict())
        isa(k, ObjectIdDict) && continue # Skip the self doc.
        out[k] = doctest(mod, k, v)
    end
    Results(mod, out)
end

function doctest(mod, obj, docs :: TypeDoc)
    out = []
    add!(out, doctest(mod, obj, docs.main))
    for s in [:fields, :meta]
        for (k, v) in getfield(docs, s)
            add!(out, doctest(mod, (obj, k), v))
        end
    end
    out
end
function doctest(mod, obj, docs :: FuncDoc)
    out = []
    add!(out, doctest(mod, obj, docs.main))
    for (k, v) in docs.meta
        add!(out, doctest(mod, (obj, k), v))
    end
    out
end
function doctest(mod, obj, docs :: MD)
    out = []
    for each in docs.content
        add!(out, runcode(mod, obj, each))
    end
    out
end
doctest(mod, obj, other) = nothing

function runcode(mod, obj, source :: Code)
    source.language == "julia" || return nothing
    result, status =
        try
            sandbox = Module()
            importmod(sandbox, mod)
            ind = 1
            out = nothing
            while ind < length(source.code)
                ex, ind = parse(source.code, ind)
                out = eval(sandbox, ex)
            end
            out, PASSED
        catch err
            err, FAILED
        end
    Result(mod, obj, status, result, source)
end
runcode(mod, obj, other) = nothing

importmod(s, m) = eval(s, Expr(:toplevel, Expr(:using, fullname(m)...)))

add!(out, result :: Vector) = append!(out, result)
add!(out, result :: Nothing) = result
add!(out, result) = push!(out, result)

end
