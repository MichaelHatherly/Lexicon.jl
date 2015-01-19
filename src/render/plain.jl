## Docs-specific rendering --------------------------------------------------------------

function writemime(io::IO, mime::MIME"text/plain", docs::Docs{:md})
    writemime(io, mime, parsed(docs))
end

function writemime(io::IO, mime::MIME"text/plain", docs::Docs{:txt})
    println(io)
    for line in split(parsed(docs), "\n")
        println(io, "  ", line)
    end
end

## General plain-text rendering - REPL --------------------------------------------------

function writemime(io::IO, mime::MIME"text/plain", qr::QueryResults)
    single = length(qr.matches) ≡ 1
    count = 1
    msg = false
    for (score, entries) in reverse!(sort(collect(qr.scores)))
        for entry in entries
            match = qr.matches[entry]
            count, msg = writemime(io, mime, match, count, qr.query.index, single)
        end
    end
    if msg && HELP_MESSAGE[1]
        println(io, """

        Note: To display documentation for a specific entry listed above append
        the corresponding number to your previous query, ie:

            help?> "help" 1""")
        HELP_MESSAGE[1] = false
    end
end

const HELP_MESSAGE = [true]

function writemime(io::IO, mime::MIME"text/plain", m::Match, count, index, single)
    cat = colorize(:blue, "\n[$(category(m.entry))]\n")
    msg = false
    if single
        # Just one entry was found to match the query.
        println(io, cat)
        for object in sort(collect(m.objects); by = x -> string(x))
            print_signature(io, object, m.entry)
            count += 1
        end
        writemime(io, mime, m.entry)
    elseif 0 < index
        # Only show the nth entry from summary output.
        for object in m.objects
            if index == count
                println(io, cat)
                print_signature(io, object, m.entry)
                writemime(io, mime, m.entry)
            end
            count += 1
        end
    else
        # Display a summary of the entries that match a query.
        for object in m.objects
            print(io, colorize(:default, lpad(count, 3) * ": "))
            print_signature(io, object, m.entry)
            count += 1
        end
        msg = true
    end
    count, msg
end

function print_signature(io::IO, object, entry)
    color = isexported(modulename(entry), object) ? :green : :default
    print(io, colorize(color, join(fullname(modulename(entry)), ".")), ".")
    println(io, colorize(:default, writeobj(object, entry)))
end

function writemime(io::IO, mime::MIME"text/plain", entry::Entry)
    # Parse docstring into AST and print it out.
    writemime(io, mime, docs(entry))

    # Print metadata if any is available
    isempty(metadata(entry)) || println(io, colorize(:green, " Details:\n"))
    for (k, v) in metadata(entry)
        if isa(v, Vector)
            println(io, "\t", k, ":")
            for line in v
                if isa(line, NTuple)
                    println(io, "\t\t", colorize(:cyan, string(line[1])), ": ", line[2])
                else
                    println(io, "\t\t", string(line))
                end
            end
        else
            println(io, "\t", k, ": ", v)
        end
    end
end
