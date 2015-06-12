["""

Stage two of generating static documentation.

Traverse the documentation tree and sort docstrings based on their position and
any given ``filter`` and ``sorter`` functions.

This stage is output format agnostic. Things such as mkdocs are done later.

"""]

"""
Cache data that is independant of output format.

This function will be called internally by the ``save`` methods prior to
generating static content. Compiled data is cached for later use so that
compilation only has to take place once.
"""
:compile!

function compile!{T}(node::Node{T})
    # Don't compile more than once.
    get(node.cache, :cached, false) && return node
    node.cache[:cached] = true
    # Do things applicable to every node type here.

    ## Nothing yet. ##

    # Dispatch to specialised method.
    compile!(T, node)
    # And finally compile each child node with the same two stage approach.
    for (n, child) in enumerate(node.children)
        compile!(child)
        isa(child, Node) && assign_id!(child, n)
    end
    node
end

function compile!(::Type{Document}, node::Node)
    assign_id!(node, 1)
    node
end

function compile!(::Type{Section}, node::Node)
    ## Nothing yet. ##
    node
end

function compile!(::Type{Page}, node::Node)
    compiled  = Dict{UTF8String, Any}()
    formatter = Format{loadformatter(node)}()
    for child in node.children
        isa(child, AbstractString) && (compiled[child] = readtext(formatter, node, child))
    end
    node.cache[:compiled] = compiled
    node
end

"""
Compile each string into a markdown AST. Aggregate adjacent modules.
"""
function compile!(::Type{Docs}, node::Node)
    compiled  = Any[]
    modules   = Set{Module}()
    formatter = Format{loadformatter(node)}()
    for child in node.children
        if isa(child, AbstractString)
            if !isempty(modules)
                push!(compiled, globmodules(node, modules))
                empty!(modules)
            end
            push!(compiled, readtext(formatter, node, child))
        else # Modules.
            push!(modules, child)
        end
    end
    # There may still be some left over modules at this point.
    isempty(modules) || push!(compiled, globmodules(node, modules))
    # Save the output for later rendering.
    node.cache[:compiled] = compiled
    node
end

# Skip anything that isn't a node.
compile!(others...) = nothing

"""
Group, filter, and sort the module contents.
"""
function globmodules(node::Node, modules::Set{Module})
    filtfunc, sortfunc = loadfuncs(node)
    output = Vector{ObjectPair}[]
    for (k, v) in groupobjects(modules)
        filter!(filtfunc, v)
        sort!(v, lt = sortfunc)
        isempty(v) || push!(output, v)
    end
    # Sort groups by their first object.
    sort!(output, lt = sortfunc, by = objects -> first(objects))
    output
end

"""
Group objects by source location.
"""
function groupobjects(modules::Set{Module})
    groups = Dict{@compat(Tuple{Int, UTF8String}), Vector{ObjectPair}}()
    for m in modules
        for obj in Cache.objects(m)
            line = Cache.getmeta(m, obj)[:textsource]
            haskey(groups, line) || (groups[line] = ObjectPair[])
            pair = ObjectPair(m, obj)
            push!(groups[line], pair)
        end
    end
    groups
end

"""
Load user-provided sorting and filtering functions, or use defaults.
"""
function loadfuncs(node::Node{Docs})
    x = Elements.findconfig(node, :filter, Function)
    y = Elements.findconfig(node, :sorter, Function)
    (isnull(x) ? (object -> true) : get(x)), (isnull(y) ? ((a, b) -> true) : get(y))
end

"""
Load user-provided formatter or use Markdown by default.
"""
function loadformatter(node::Node)
    x = Elements.findconfig(node, :format, DataType)
    isnull(x) ? MarkdownFormatter : get(x)
end

"""
Assign an id to the given ``node``.

Defaults to the node type and position in ``.children`` vector. A custom id
may be provided by passing a ``Symbol`` to the node constructor.

    document(:myname,
        section(
            :mysection,
        ),
        section(
        )
    )

The ``Node{Document}`` and first ``Node{Section}`` will have custom ids, whereas
the second section will have the generated id ``:Section-2``.
"""
function assign_id!{T}(node::Node{T}, n)
    node.cache[:id] = haskey(node.data, :id) ? node.data[:id] :
        symbol(string(T.name.name, "-", n))
end

"""
Get the vector of symbols that uniquely identify a node in a document tree.
"""
function get_full_id(node::Node)
    symbols = Symbol[node.cache[:id]]
    while isdefined(node, :parent)
        node = node.parent
        unshift!(symbols, node.cache[:id])
    end
    symbols
end
