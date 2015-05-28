import Lexicon.Elements: document, section, page, docs

## Testing. ##
 
import Docile
 
pages = [page("# $(ucfirst(f))", "$(f).md") for f in [
             "introduction",
             "syntax",
             "metamacros"
             ]
         ]
 
mods  = [docs("### ``$(m)``", m) for m in [
             Docile,
             Docile.Collector,
             Docile.Formats,
             Docile.Extensions
             ]
         ]
 
out = document(
    section(
        :manual,
        pages...,
        title  = "Manual Pages",
        ),
    section(
        :api,
        page(
            mods...,
            title  = "Function & Methods",
            filter = obj -> isa(obj, Function) || isa(obj, Method),
            ),
        page(
            mods...,
            title  = "Types",
            filter = obj -> isa(obj, DataType),
            ),
        ),
    title = "Docile Documentation",
    )
 
writemime(STDOUT, "text/plain", out)
