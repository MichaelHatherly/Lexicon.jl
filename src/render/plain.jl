## Docs-specific rendering --------------------------------------------------------------

function writemime(io::IO, mime::MIME"text/plain", docs::Docile.Interface.Docs{:md})
    Markdown.term(io, parsed(docs))
end

function writemime(io::IO, mime::MIME"text/plain", docs::Docile.Interface.Docs{:txt})
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
    for (score, entries) in reverse!(sort([(a, b) for (a, b) in qr.scores]))
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

function writemime(io::IO, mime::MIME"text/plain", entry::Entry, config::Config = Config())
    # Parse docstring into AST and print it out with additional space above and below.
    println(io)
    writemime(io, mime, docs(entry))
    println(io)

    # Print metadata if any is available
    if has_output_metadata(entry, config)
        println(io, colorize(:green, " Details:\n"))
        for m in config.metadata_order
            if haskey(entry.data, m)
                v = entry.data[m]
                if isa(v, Vector)
                    println(io, "\t", m, ":")
                    for line in v
                        if isa(line, NTuple)
                            println(io, "\t\t", colorize(:cyan, string(line[1])), ": ", line[2])
                        else
                            println(io, "\t\t", string(line))
                        end
                    end
                else
                    println(io, "\t", m, ": ", v)
                end
            end
        end
    end
end

function colorize(color::Symbol, text::AbstractString)
    buf = IOBuffer()
    print_with_color(color, buf, text)
    takebuf_string(buf)
end
