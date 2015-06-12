"""
Stores a documented object and the module it is found in.
"""
immutable ObjectPair
    mod :: Module
    obj :: Any
end

typealias Object Union(
    Module,
    Function,
    Method,
    DataType,
    QualifiedSymbol,
    Aside,
    )
