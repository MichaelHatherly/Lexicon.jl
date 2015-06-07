"""
Error type thrown by query construction methods.
"""
immutable QueryBuildError <: Exception
    msg ::UTF8String
end

abstract Term

"""
``Query`` objects store trees of ``Term`` nodes to find documentation in Docile.

- ``term``:  The root node of the term tree.
- ``index``: Select which docstring to display from query results.

If ``index`` is ``0`` then a summary is shown when more than one result is found
for a given query.
"""
immutable Query
    term  :: Term
    index :: Int
    Query(term, index) = new(term, index)
end

(==)(a::Query, b::Query) =
    (a.term  == b.term) &&
    (a.index == b.index)

## Data Terms. ##

"""
Terms storing values.
"""
abstract DataTerm <: Term

"""
Match against simple text.

Syntax

    "text"

will match any docstring containing the text "text".
"""
immutable Text <: DataTerm
    text :: UTF8String
end

(==)(a::Text, b::Text) = a.text == b.text

"""
Match the object ``object`` or it's symbolic representation.

The ``symbol`` field is used when matching against globals and typealiases.

Syntax

    foobar

matches object ``foobar`` or symbol ``:foobar``.

    Baz.foobar

matches object ``Baz.foobar`` or symbol ``:foobar`` in module ``Baz``.
"""
immutable Object <: DataTerm
    symbol :: Symbol
    object :: Any
end

"""
Match metadata key/value pairs.

Syntax

    [k = v, ...]

will match documented objects with metadata field ``:k`` whose value is ``v``.

    [k, ...]

matches field ``:k``. It's value is unimportant.
"""
immutable Metadata <: DataTerm
    metadata :: Dict{Symbol, Any}
    Metadata(args) = new(Dict{Symbol, Any}(args))
end

(==)(a::Metadata, b::Metadata) = a.metadata == b.metadata

## Type Terms. ##

"""
Terms storing types.
"""
abstract TypeTerm <: Term

"""
Matches all objects with a type signature ``signature``.

Syntax

    (Int, Int, Any)

matches all methods with signature ``(Int, Int, Any)``.

    foobar(UTF8String, Bool)

matches any methods of function ``foobar`` with type signature
``(UTF8String, Bool)``.
"""
immutable ArgumentTypes <: TypeTerm
    signature
    ArgumentTypes(sig) = new(to_tuple_type(sig))
end

"""
Matches all objects with a return type of ``signature``.

Syntax

    ::(Bool, Int)

matches methods with a computed return type of ``(Bool, Int)``.

    foobar::Int

match all methods of function ``foobar`` with a return type of ``Int``.
"""
immutable ReturnTypes <: TypeTerm
    signature
    ReturnTypes(sig) = new(to_tuple_type(sig))
end

"""
Logical operations on ``TypeTerm`` and ``DataType`` nodes.
"""
abstract LogicTerm <: Term

"""
Matches query when both ``left`` and ``right`` fields match.

Syntax

    "text" & (Int, Int)

matches all docstrings containing "text" where the documented object is a two
argument method whose signature is ``(Int, Int)``.
"""
immutable And <: LogicTerm
    left  :: Term
    right :: Term
end

(==)(a::And, b::And) = (a.left == b.left) && (a.right == b.right)

"""
Matches query when either ``left`` or ``right`` fields match.

Syntax

    "text" | "string"

matches any docstring containing either "text" or "string".

    [category = :macro] | [category = :global]

matches all documented macros and globals.
"""
immutable Or <: LogicTerm
    left  :: Term
    right :: Term
end

(==)(a::Or, b::Or) = (a.left == b.left) && (a.right == b.right)

"""
Matches query when the field ``term`` does not match.

Syntax

    !"text"

matches any docstring that does not contain the string "text".

    !Lexicon.Queries.Not

matches any object that is not ``Lexicon.Queries.Not``. (Not a terribly useful
search term by itself.)

"""
immutable Not <: LogicTerm
    term :: Term
end

(==)(a::Not, b::Not) = a.term == b.term

"""
A type used in metadata syntax, ``[k = v, ...]``, to allow for matching
against *any* value ``v``.

The syntax:

    [k1, k2 = v2]

will generate a metadata matching node with

    Dict{Symbol, Any}(:k1 => MatchAnything(), :k2 => v2)

``:k1 => MatchAnything()`` will then match any metadata where the key is ``:k1``
regardless of the value.
"""
immutable MatchAnything end
