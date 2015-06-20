# Output Types. #

"""
A documented object matching query passed to ``runquery``.
"""
immutable Result
    mod    :: Module
    object :: Any
    score  :: Float64
end

"""
List of all matching ``Result`` objects for query passed to ``runquery``.
"""
immutable Results
    query :: Query
    data  :: Vector{Result}
    Results(query::Query) = new(query, Result[])
end

# Run queries. #

"""
Find documented objects matching ``query``. Return as a ``Results`` object.
"""
function runquery(query::Query)
    results = Results(query)
    for m in Docile.Cache.loadedmodules()
        for obj in Docile.Cache.objects(m)
            score = getscore(query.term, m, obj)
            score > 0 && push!(results.data, Result(m, obj, score))
        end
    end
    results
end

# Query Scoring. #

# TODO: fine-tune values.

## Text. ##

function getscore(term::Text, m, obj)
    rawdocs = Docile.Cache.getraw(m, obj)
    pieces  = split(rawdocs, term.text)
    (length(pieces) - 1) / length(rawdocs)
end

## Regular expressions. ##

function getscore(term::RegexTerm, m, obj)
    rawdocs = Docile.Cache.getraw(m, obj)
    pieces  = matchall(term.regex, rawdocs)
    length(pieces) / length(rawdocs)
end

## Object. ##

function getscore(term::Object, m, obj::Docile.Collector.QualifiedSymbol)
    score =  term.symbol == obj.sym      ? 0.5 : 0.0
    score += m == obj.mod && score > 0.0 ? 0.5 : 0.0
end

function getscore(term::Object, m, obj)
    score =  term.object == obj ? 0.8 : 0.0
    score += term.object == m   ? 0.2 : 0.0
end

function getscore(term::Object, m, obj::Method)
    score = _getscore(term.object, m, obj)
    score += term.object == m ? 0.2 : 0.0
end

function _getscore(f::Base.Callable, m::Module, obj::Method)
    _isgeneric(f) && for meth in methods(f)
        meth == obj && return 0.5
    end
    0.0
end
_getscore(other, m, obj::Method) = 0.0

_isgeneric(f::DataType) = true
_isgeneric(f::Function) = isgeneric(f)

## Metadata. ##

function getscore(term::Metadata, m, obj)
    meta  = Docile.Cache.getmeta(m, obj)
    score = 0.0
    for (k, v) in term.metadata
        if haskey(meta, k)
            if v == meta[k]
                score += 1.0
            elseif v == MatchAnything()
                score += 0.5
            end
        end
    end
    score
end

## ArgumentTypes. ##

getscore(term::ArgumentTypes, m, obj::Method) =
    Base.typeseq(term.signature, obj.sig) ? 1.0 : 0.0

getscore(term::ArgumentTypes, m, obj) = 0.0

## ReturnTypes. ##

getscore(term::ReturnTypes, m, obj::Method) =
    Base.typeseq(returned(obj), term.signature) ? 1.0 : 0.0

getscore(term::ReturnTypes, m, obj) = 0.0

## Logic. ##

function getscore(term::And, m, obj)
    left  = getscore(term.left,  m, obj)
    right = getscore(term.right, m, obj)
    (left > 0 && right > 0) ? (left + right) : 0.0
end

function getscore(term::Or, m, obj)
    left  = getscore(term.left,  m, obj)
    right = getscore(term.right, m, obj)
    (left > 0 || right > 0) ? (left + right) : 0.0
end

getscore(term::Not, m, obj) = getscore(term.term, m, obj) > 0 ? 0.0 : 1.0
