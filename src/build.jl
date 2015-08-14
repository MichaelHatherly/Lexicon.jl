# This file generated the Markdown documentation files.

# The @file macro generates the documentation for a particular file
# where the {{method1, methods2}} includes the documentation for each method
# via the `buildwriter` function.

# Currently this prints the methodtable followed by the docstring.

macro file(fn, md_string, m::Module) buildfile(fn, md_string, m) end

function generate_for(m::Module, file_names...; doc_dir="docs", gen_dir="_generated")
    eval(Expr(:toplevel, Expr(:using, symbol(m))))
    dd = joinpath(Pkg.dir(string(m)), doc_dir)
    for file_name in file_names
        eval(quote
            @file $(joinpath(dd, gen_dir, file_name)) $(open(readall, joinpath(dd, file_name))) $m
        end)
    end
end

buildfile(t, s::AbstractString, m::Module) = buildfile(t, Expr(:string, s), m)

buildfile(target, source::Expr, m::Module) = quote
    open(joinpath(dirname(@__FILE__), $(esc(target))), "w") do file
        println(" - '$($(esc(target)))'")
        println(file, "<!-- AUTOGENERATED. See 'doc/build.jl' for source. -->")
        $(Expr(:block, [buildwriter(arg, m) for arg in source.args]...))
    end
end

buildwriter(ex::Expr, m::Module) = :(print(file, $(esc(ex))))

buildwriter(t::AbstractString, m::Module) = Expr(:block,
    [buildwriter(p, iseven(n), m) for (n, p) in enumerate(split(t, r"{{|}}"))]...
)

buildwriter(part, isdef, m) = isdef ?
    begin
        parts = Expr(:vect, [:(($(parse(p))), $(local_doc(parse(p); from=m))) for p in filter(x -> strip(x) != "", split(part, r"\s*[, \n]\s*"))]...)
        quote
            for (f, docstring) in $(esc(parts))
                if isa(f, Function)
                    println(file, "### ", first(methods(f)).func.code.name)
                    println(file)
                end
                if has_h1_to_h3(docstring)
                    println("WARN: docstring for ", f, " contains h1 - h3. ",
                          "This may confuse formatting.")
                end
                writemime(file, "text/plain", docstring)
                println(file)
                if isa(f, Function)
                    md_methodtable(file, f, $m)
                end
             end
        end
    end :
    :(print(file, warn_if_h1($(esc(part)))))

function warn_if_h1(part)
    if ismatch(r"(^|\n)\s{0,3}#[^#]", part) || ismatch(r"[^\n]\n\s{0,3}===", part)
        println("WARN: h1 detected in markdown file, this may cause ",
                "formatting errors in mkdocs. ")
        println("      Titles should be defined in mkdocs.yml.")
    end
    part
end

function md_methodtable(io, f, m::Module)
    println(io, "```")
    # We only consider methods with are defined in the parent (project) directory
    pd = joinpath(Pkg.dir(), string(module_name(m)))
    meths = filter(x -> startswith(string(x.func.code.file), pd), methods(f))
    for (i, meth) in enumerate(meths)
        md_method(io, meth, i, m)
    end
    println(io, "```")
    print(io, "*Source:")
    for (i, meth) in enumerate(meths)
        print(io, " [", i, "](", method_link(meth, m), ")")
    end
    println(io, "*.")
    println(io)
end
function md_method(io, meth, i, m::Module)
    # We only print methods with are defined in the parent (project) directory
    pd = joinpath(Pkg.dir(), string(module_name(m)))
    if !(startswith(string(meth.func.code.file), pd))
        return
    end
    print(io, i, "  ",  meth.func.code.name)
    tv, decls, file, line = Base.arg_decl_parts(meth)
    if !isempty(tv)
        Base.show_delim_array(io, tv, '{', ',', '}', false)
    end
    print(io, "(")
    print_joined(io, [isempty(d[2]) ? "$(d[1])" : "$(d[1])::$(d[2])" for d in decls],
                 ", ", ", ")
    print(io, ")")
    println(io)
end

function has_h1_to_h3(md::Markdown.MD)
    for i in 1:length(md)
        s = md[i]
        if isa(s, Markdown.Header) && typeof(s).parameters[1] <= 3
            return true
        end
    end
    return false
end

function local_doc(func::Symbol; from = Main, include_submodules = true)
    local_doc(from.(func); from=from, include_submodules=include_submodules)
end
function local_doc(func::Expr; from = Main, include_submodules = true)
    local_doc(eval(func); from=from, include_submodules=include_submodules)
end
function local_doc(func::Function; from = Main, include_submodules = true)
    if isa(func, Module)
        # TODO work with submodules
        return from.__META__[func]
    end
    out = IOBuffer()
    for m in (include_submodules ? submodules(from) : Set([from]))
        if isdefined(m, :__META__)
            meta = m.__META__
            if haskey(meta, func)
                if meta[func].main != nothing
                    writemime(out, "text/plain", meta[func].main)
                    println(out)
                    println(out)
                end
                for each in meta[func].order
                    writemime(out, "text/plain", Base.Docs.doc(func, each))
                    # two lines may be required to end the block.
                    println(out)
                    println(out)
                end
            end
        end
    end
    plain_docstring = takebuf_string(out)
    if plain_docstring == ""
        println("WARN: No docstring found for ", func)
    end
    return Markdown.parse(plain_docstring)

end

function submodules(mod::Module)
   out = Set([mod])
   for name in names(mod, true)
       if isdefined(mod, name)
           object = getfield(mod, name)
           validmodule(mod, object) && union!(out, submodules(object))
       end
   end
   out
end

validmodule(mod::Module, object::Module) = object ≠ mod && object ≠ Main
validmodule(::Module, other) = false

function method_link(meth::Method, m::Module)
    u, commit, root = module_url(meth, m)
    file = relpath(string(meth.func.code.file), root)
    line = meth.func.code.line

    return "https://github.com/$u/tree/$commit/$file#L$line"
end

const _URL_CACHE = Dict{Module, Any}()
function module_url(meth::Method, m::Module)
    found = get(_URL_CACHE, m, nothing)
    if found != nothing
        return found
    end
    d = dirname(string(meth.func.code.file))
    u = Pkg.Git.readchomp(`config remote.origin.url`, dir=d)
    u = match(Pkg.Git.GITHUB_REGEX,u).captures[1]

    root = cd(d) do # dir=d confuses --show-toplevel, apparently
        Pkg.Git.readchomp(`rev-parse --show-toplevel`)
    end
    root = @windows? replace(root, "/", "\\") : root

    commit = Pkg.Git.readchomp(`rev-parse HEAD`, dir=root)
    return _URL_CACHE[m] = (u, commit, root)
end

