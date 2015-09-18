abstract Status

type Passed <: Status end
type Failed <: Status end
type Skipped <: Status end

type Result{S <: Status}
    codeblock::AbstractString
    exception::Exception
    location::@compat(Tuple{Any, Int})

    Result(codeblock, location) = new(codeblock, ErrorException(""), location)
    Result(codeblock, exception, location) = new(codeblock, exception, location)
end

function writemime{S <: Status}(io::IO, mime::MIME"text/plain", r::Result{S})
    println(io, """
     Entry: $(r.location[1])
     Block: $(r.location[2])
    Status: $(S)
    """)
    indented(io, r.codeblock)
    printexception(io, mime, r)
end

function printexception(io::IO, ::MIME"text/plain", r::Result{Failed})
    println(io, "\n", "Exception:", "\n")
    indented(io, string(r.exception))
end
printexception(io::IO, ::MIME"text/plain", r::Result{Passed}) = println(io)
printexception(io::IO, ::MIME"text/plain", r::Result{Skipped}) = nothing

function indented(io::IO, str::AbstractString, n::Int = 4)
    for line in split(str, "\n")
        println(io, " "^n, line)
    end
end

type Results{S <: Status}
    results::Vector{Result{S}}

    Results() = new(Results{S}[])
end

function writemime(io::IO, mime::MIME"text/plain", rs::Results)
    for r in rs.results
        writemime(io, mime, r)
    end
end

length(rs::Results) = length(rs.results)

type Summary
    modname::Module
    passed::Results{Passed}
    failed::Results{Failed}
    skipped::Results{Skipped}

    Summary(modname) = new(modname, Results{Passed}(), Results{Failed}(), Results{Skipped}())
end

for (T, f, docs) in [(Passed, :passed, "passed"),
                     (Failed, :failed, "failed"),
                     (Skipped, :skipped, "were skipped during")]
    @eval begin
        $(f)(s::Summary) = s.$(f)
        push!(s::Summary, r::Result{$(T)}) = push!($(f)(s).results, r)
    end
end

function writemime(io::IO, mime::MIME"text/plain", s::Summary)
    println(io, "[module summary]\n")
    println(io, """
     *   module: $(s.modname)
     * exported: $(length(names(s.modname)))
     *  entries: $(length(entries(documentation(s.modname))))
    """)

    npassed, nfailed, nskipped = map(length, (passed(s), failed(s), skipped(s)))
    total = npassed + nfailed + nskipped

    println(io, "[doctest summary]\n")
    @printf(io, " * pass: %5d / %d\n", npassed, total)
    @printf(io, " * fail: %5d / %d\n", nfailed, total)
    @printf(io, " * skip: %5d / %d\n", nskipped, total)
end

"""
Run code blocks in the docstrings of the specified module `modname`.
Returns a `Summary` of the results.

Code blocks may be skipped by adding an extra newline at the end of the block.

**Example:**

```julia_skip
doctest(Lexicon)
```
"""
function doctest(modname::Module)
    doc = documentation(modname)
    println("running doctest on $(modname)...")
    summ = Summary(modname)
    for (obj, entry) in entries(doc)
        isa(docs(entry), Docile.Interface.Docs{:md}) || continue # Markdown is the only supported format.
        count = 0
        for block in parsed(docs(entry)).content
            if iscode(block)
                count += 1
                try
                    if !runnable(block) # skip code block with trailing newline
                        push!(summ, Result{Skipped}(block.code, (obj, count)))
                        continue
                    end
                    runcode(block, modname)
                catch err
                    push!(summ, Result{Failed}(block.code, err, (obj, count)))
                    continue
                end
                push!(summ, Result{Passed}(block.code, (obj, count)))
            end
        end
    end
    summ
end

iscode(::Markdown.Code) = true
iscode(::Any)           = false

runnable(code::Markdown.Code) =
    contains(code.language, "julia") &&
    !(contains(code.language, "skip"))

function runcode(block, modname)
    sandbox = Module(:__SANDBOX__)
    eval(sandbox, Expr(:toplevel, Expr(:using, symbol("$(modname)"))))
    i = 1
    while i < length(block.code)
        ex, i = parse(block.code, i)
        eval(sandbox, ex)
    end
end
