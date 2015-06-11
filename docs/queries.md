# Query Syntax

Lexicon includes a query syntax that can help to narrow down results when using
the REPL's ``?`` mode. It allows searching by object, text, metadata, type
signatures and return types.  Combinations of these may be searched using
logical operators ``&``, ``|``, and ``!``.

## Usage

Lexicon integrates it's query system directly into the REPL's ``?`` mode and
displays it's results after those shown normally by Julia.

To search for all documentation containing the text "module" in module ``Docile.Cache``
we can enter the query

    help?> "module" & Docile.Cache

In many cases Lexicon will find several results that match the provided query.
When this does happen all the results are numbered by relevance (``1`` being
most relevant). To view the full documentation associated with a particular
result the previous query can then be rerun (by pressing the up-arrow) and
appending a number to it.

    help?> "module" & Docile.Cache 5

*Note:* Results for exported objects have their module highlighted in green.

### Logic Operators

The operators ``&`` (AND), ``|`` (OR), and ``!`` (NOT) are used to combine the
basic query terms together and are parsed in the same way as in Julia source
code. Brackets may be used to order the terms correctly.

To search for documentation related to the operators themselves, or any other
Julia operator, they must be wrapped in brackets:

    help?> (&) | (+)

### Type Queries

Methods may be queried based on their signatures and return types. Signatures
are specified using tuple syntax, while return types use ``::`` syntax.

    help?> (Int, Any)

    help?> ::Vector

    help?> (Int, Any)::Vector

### Metadata

Docile stores metadata key/value pairs for each documented object. These can be
queried using ``[key = value, ...]`` syntax. The ``key`` must be a valid Julian
identifier and the ``value`` is optional. When ``value`` is not specified then
any documentation with the metadata key ``key`` will be matched.

    help?> [category = :macro]

    help?> [author] | [authors]
