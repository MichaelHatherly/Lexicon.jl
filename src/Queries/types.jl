"""
Error type thrown by query construction methods."
"""
immutable QueryBuildError <: Exception
    msg ::UTF8String
end

abstract Term

immutable Query
    term  :: Term
    mods  :: Set{Module}
    index :: Int
    Query(term, vector, index) = new(term, modules(vector), index)
end

(==)(a::Query, b::Query) =
    (a.term  == b.term) &&
    (a.mods  == b.mods) &&
    (a.index == b.index)

## Data Terms. ##

abstract DataTerm <: Term

immutable Text <: DataTerm
    text :: UTF8String
end

(==)(a::Text, b::Text) = a.text == b.text

immutable Object <: DataTerm
    symbol :: Symbol
    object :: Any
end

immutable Metadata <: DataTerm
    metadata :: Dict{Symbol, Any}
    Metadata(args) = new(Dict{Symbol, Any}(args))
end

(==)(a::Metadata, b::Metadata) = a.metadata == b.metadata

## Type Terms. ##

abstract TypeTerm <: Term

immutable ArgumentTypes <: TypeTerm
    signature :: Tuple
end
immutable ReturnTypes <: TypeTerm
    signature :: Tuple
end

abstract LogicTerm <: Term

immutable And <: LogicTerm
    left  :: Term
    right :: Term
end

(==)(a::And, b::And) = (a.left == b.left) && (a.right == b.right)

immutable Or <: LogicTerm
    left  :: Term
    right :: Term
end

(==)(a::Or, b::Or) = (a.left == b.left) && (a.right == b.right)

immutable Not <: LogicTerm
    term :: Term
end

(==)(a::Not, b::Not) = a.term == b.term

immutable MatchAnything end
