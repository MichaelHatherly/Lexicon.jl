using Lexicon

const DIR = dirname(@__FILE__)

for version in ARGS
    save(joinpath(DIR, "site", version, "index.html"), Lexicon)
end
