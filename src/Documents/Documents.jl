module Documents

"!!include(../docs/documents)"
Documents

export document, section, page, preformat, pages, config

import Docile.Collector: findexternal


include("nodes.jl")

end
