using Docile, Docile.Interface, Lexicon

const PKGS = [("Docile", [Docile, Docile.Interface], :CATEGORY),
             ("Lexicon", [Lexicon], :SIMPLE)]

cd(dirname(@__FILE__)) do

    # Generate and save the contents of docstrings as markdown files.
    config = nothing
    for (pkg, modules, subheader) in PKGS
        for m in modules
            filename = joinpath("docs", pkg, "$(module_name(m)).md")
            try
               config = save(filename, m; md_genindex=true, md_permalink=true, mdstyle_objname="**", 
                                                                            md_subheader=subheader)
            catch err
                println(err)
                exit(1)
            end
        end
    end
    savegenindex("docs/api_index/genindex.md", config; md_subheader=:CATEGORY)
end
