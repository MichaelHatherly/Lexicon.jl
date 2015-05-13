# API-INDEX


## MODULE: Lexicon

---

## Methods [Exported]

[doctest(modname::Module)](Lexicon.md#method__doctest.1)  Run code blocks in the docstrings of the specified module `modname`.

[query(f::Function, sig)](Lexicon.md#method__query.1)  Search loaded documentation for methods of generic function `f` that match `sig`.

[query(f::Function, sig, index)](Lexicon.md#method__query.2)  Search loaded documentation for methods of generic function `f` that match `sig`.

[save(file::AbstractString, index::Lexicon.Index, config::Lexicon.Config)](Lexicon.md#method__save.1)  Saves an *API-Index* to `file`.

[save(file::AbstractString, modulename::Module, config::Lexicon.Config)](Lexicon.md#method__save.2)  Write the documentation stored in `modulename` to the specified `file`.

---

## Types [Exported]

[Lexicon.Config](Lexicon.md#type__config.1)  User adjustable Lexicon configuration.

[Lexicon.EachEntry](Lexicon.md#type__eachentry.1)  Iterator type for Metadata Entries with sorting options.

---

## Macros [Exported]

[@query(args...)](Lexicon.md#macro___query.1)  Create a `Query` object from the provided `args`.

---

## Methods [Internal]

[calculate_score(query, text, object)](Lexicon.md#method__calculate_score.1)  Basic text importance scoring.

[call(::Type{Lexicon.Config})](Lexicon.md#method__call.1)  Returns a default Config. If any args... are given these will overwrite the defaults.

[call(::Type{Lexicon.EachEntry}, docs::Docile.Legacy.Metadata)](Lexicon.md#method__call.2)  Constructor.

[filter(docs::Docile.Legacy.Metadata)](Lexicon.md#method__filter.1)  Filter Metadata based on categories or file source.

[filter(f::Function, docs::Docile.Legacy.Metadata)](Lexicon.md#method__filter.2)  Filter Metadata based on a function.

---

## Types [Internal]

[Lexicon.Match](Lexicon.md#type__match.1)  An entry and the set of all objects that are linked to it.

[Lexicon.Query](Lexicon.md#type__query.1)  Holds the parsed user query.

[Lexicon.QueryResults](Lexicon.md#type__queryresults.1)  Stores the matching entries resulting from running a query.

---

## Typealiass [Internal]

[Queryable](Lexicon.md#typealias__queryable.1)  Types that can be queried.

