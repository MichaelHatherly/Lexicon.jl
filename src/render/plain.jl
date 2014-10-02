## Docs-specific rendering ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/plain", docs::Docs{:md})
    writemime(io, mime, parsed(docs))    
end

function writemime(io::IO, mime::MIME"text/plain", docs::Docs{:txt})
    println(io)
    for line in split(parsed(docs), "\n")
        println(io, "  ", line)
    end
end

## General plain-text rendering - REPL ––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/plain", response::Response)
    for cat in sort(collect(keys(response.categories)))
        writemime(io, mime, response.categories[cat])
    end
end

function writemime(io::IO, mime::MIME"text/plain", ents::MatchingEntries)
    for (ent, objs) in ents.entries
        # Header and signature.
        println(io, colorize(:blue, "\n[$(category(ent))]\n"))
        for obj in sort(collect(objs); by = x -> string(x))
            print(io, " > ", colorize(:white, join(fullname(modulename(ent)), ".") * "."))
            println(io, colorize(:cyan, writeobj(obj)))
        end

        # Main section of an entry's documentation.
        writemime(io, mime, ent)
    end
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

function writemime(io::IO, mime::MIME"text/plain", manual::Manual)
    for page in pages(manual)
        println(io, colorize(:green, "File: "), file(page))
        writemime(io, mime, docs(page))
    end
end
