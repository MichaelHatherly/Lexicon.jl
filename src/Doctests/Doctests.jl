module Doctests

"""

"""
Doctests

using Compat

import Docile:

    Cache

import ..Utilities

import ..Markdown


"""
Stores ``doctest`` results for a module.
"""
type Summary
    mod       :: Module
    passed    :: ObjectIdDict
    skipped   :: ObjectIdDict
    failed    :: ObjectIdDict
    emptydocs :: ObjectIdDict

    Summary(mod) = new(
        mod,
        ObjectIdDict(),
        ObjectIdDict(),
        ObjectIdDict(),
        ObjectIdDict(),
        )
end

function Base.writemime(io::IO, ::MIME"text/plain", summary::Summary)
    text = """

    # '$(summary.mod)' Doctest Results

    ## General

    - $(countresults(summary.mod, summary.emptydocs)) empty docstrings.

    ## Codeblocks

    - $(countresults(summary.mod, summary.passed)) passed.
    - $(countresults(summary.mod, summary.skipped)) skipped.
    - $(countresults(summary.mod, summary.failed)) failed.
    """
    print(io, text)
end

"""
Count total number of results in each category of a ``Summary`` object.
"""
function countresults(mod::Module, dict::ObjectIdDict)
    seen  = Set{@compat(Tuple{Int, UTF8String})}()
    count = 0
    for (obj, results) in dict
        lineinfo = Cache.getmeta(mod, obj)[:textsource]
        if lineinfo ∉ seen
            push!(seen, lineinfo)
            count += length(results)
        end
    end
    count
end

update!(s::Summary, obj, error::Exception, block) = updatedict!(s.failed, obj, (error, block))
update!(s::Summary, obj, result, block)           = updatedict!(s.passed, obj, (result, block))
update!(s::Summary, obj, block)                   = updatedict!(s.skipped, obj, block)

function updatedict!(dict::ObjectIdDict, obj, data)
    haskey(dict, obj) || (dict[obj] = Any[])
    push!(dict[obj], data)
end

"""
Check the docstrings of a module ``mod``. Currently the checks done are:

- check for any empty docstrings
- run code blocks and store results
"""
function doctest(mod::Module)
    Utilities.message("doctesting '$(mod)'...")
    summary = Summary(mod)
    for obj in Cache.objects(mod)
        checkempties!(summary, obj)
        for block in Cache.getparsed(mod, obj).content
            runcode!(summary, obj, block)
        end
    end
    summary
end

"""
Check that a docstring for object ``obj`` in module ``mod`` is not empty.
"""
function checkempties!(summary, obj)
    rawdocs = strip(Cache.getraw(summary.mod, obj))
    isempty(rawdocs) && (summary.emptydocs[obj] = 1)
    nothing
end

"""
Evaluate each code block in an object's docstring.

Code blocks that do not specify their ``.language`` field as "julia" are skipped, ie.

    ```
    # ...
    ```

or indented

        # ...

are skipped while

    ```julia
    # ...
    ```

is not.

If "preamble" code is found for the object then it is prepended to the code
block. The module in which the docstring is written is also automatically
imported with a ``using`` statement.

The preamble can be set for a docstring by using the ``!!set`` metamacro:

    \"\"\"
    \\!!set(preamble:
    # Preamble code goes here...
    )

    ```julia
    # Code using the preamble...
    ```
    \"\"\"
    f(x) = x

"""
function runcode!(summary::Summary, obj, block::Markdown.Code)
    if block.language == "julia"
        # Add the code block's preamble and automatic ``using modname`` statement.
        preamble = Cache.findmeta(summary.mod, obj, :preamble, UTF8String)
        code = """
        $(isnull(preamble) ? "" : get(preamble))

        $(block.code)
        """
        # Create a new module to run to code in to avoid unwanted interaction with other blocks.
        sandbox = Module()
        eval(sandbox, Expr(:toplevel, Expr(:using, fullname(summary.mod)...)))
        # Evaluate each expression separately until an error occurs.
        result = try
            i = 1
            out = nothing
            while i < length(code)
                ex, i = parse(code, i)
                out = eval(sandbox, ex)
            end
            out
        catch err
            err
        end
        update!(summary, obj, result, block)
    else
        update!(summary, obj, block)
    end
    nothing
end
runcode!(others...) = nothing

end
