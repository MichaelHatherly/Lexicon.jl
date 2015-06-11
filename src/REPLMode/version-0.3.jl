function help(line)
    nobase = contains(line, "::") || ismatch(Queries.INTEGER_REGEX, line)
    ex = nobase ? nothing : parse("Base.Help.@help $(line)", raise = false)
    quote
        try
            $(ex)
        catch
        end
        println()
        $(runquery(line))
    end
end
