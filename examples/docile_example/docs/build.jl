import Lexicon

import Lexicon.Documents: section, document, page, preformat

import Lexicon.Utilities: packagemodules

import Lexicon.Extensions: textfile

import Lexicon.Render: save, markdown


import Docile: Cache


out = document("TestDocumentation",
    section("Introduction",
        page("index",
            textfile("index.md"),
            ),
        ),
    section("Manual",
        preformat("Manual",
            ("Overview",   "manual.md"),
            ("Syntax",     "syntax.md"),
            ("Metamacros", "metamacros.md"),
            ),
        ),
    section("API",
        packagemodules(Docile),
        ),
    )

save(markdown("out", out); remove_destination=true)
