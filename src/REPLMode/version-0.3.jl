function help(line, indexed = ismatch(Queries.INTEGER_REGEX, line))
    quote
        $(indexed ? nothing : parse("Base.Help.@help $(line)", raise = false))
        println()
        $(runquery(line))
    end
end
