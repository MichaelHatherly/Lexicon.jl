using Docile, Lexicon

const api_directory = "api"
const modules = [Lexicon]

"""
Example of customary MDSTYLE
"""
const MDSTYLE = Dict{Symbol, ByteString}([
  (:header         , "#"),
  (:objname        , "###"),
  (:meta           , "**"),
  (:exported       , "##"),
  (:internal       , "##"),
])

cd(dirname(@__FILE__)) do

    # Run the doctests *before* we start to generate *any* documentation.
    for m in modules
        failures = failed(doctest(m))
        if !isempty(failures.results)
            println("\nDoctests failed, aborting commit.\n")
            display(failures)
            exit(1) # Bail when doctests fail.
        end
    end

    # Generate and save the contents of docstrings as markdown files.
    # Example of customary STYLE for API Index
    plmain = startgenidx(joinpath(api_directory, "genindex.md"); headerstyle = "#", modnamestyle = "##")
    for m in modules
        filename = joinpath(api_directory, "$(module_name(m)).md")
        try
            save(filename, m, plmain)
        catch err
            println(err)
            exit(1)
        end
    end
    # To actually save the API Index to: `genindex.md`: If not index page is needed this can be skipped
    savegenidx(plmain)

    # Add a reminder not to edit the generated files.
    open(joinpath(api_directory, "README.md"), "w") do f
        print(f, """
        Files in this directory are generated using the `build.jl` script. Make
        all changes to the originating docstrings/files rather than these ones.

        Documentation should *only* be build directly on the `master` branch.
        Source links would otherwise become unavailable should a branch be
        deleted from the `origin`. This means potential pull request authors
        *should not* run the build script when filing a PR.
        """)
    end

    info("Adding all documentation changes in $(api_directory) to this commit.")
    success(`git add $(api_directory)`) || exit(1)

end
