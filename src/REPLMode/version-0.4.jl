function help(line)
    nobase = contains(line, "::") || ismatch(Queries.INTEGER_REGEX, line)
    ex, lex =
        if isdefined(Base.Docs, :keywords) && haskey(Base.Docs.keywords, symbol(line))
            :(Base.Docs.@repl $(symbol(line))), nothing
        else
            nobase ? nothing : parse("Base.Docs.@repl $(line)", raise = false), runquery(line)
        end
    ex =
        if isexpr(ex, :macrocall)
            if length(ex.args) ≡ 2 && isa(ex.args[2], AbstractString)
                :(Base.apropos($(ex.args[2])); println())
            else
                result = gensym()
                quote
                    $(result) = $(ex)
                    $(result) ≡ nothing || display($(result))
                end
            end
        end
    quote
        try
            $(ex)
        catch
        end
        $(lex)
    end
end
